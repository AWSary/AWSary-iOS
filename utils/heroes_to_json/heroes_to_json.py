import requests
import json
import time
from bs4 import BeautifulSoup
import unicodedata

# URL to fetch AWS Heroes data
url = "https://aws.amazon.com/api/dirs/items/search?item.directoryId=community-heroes&sort_by=item.additionalFields.sortPosition&sort_order=asc&size=1000&item.locale=en_US&tags.id=!community-heroes%23alumni%23alumni-hero"

def fetch_aws_heroes_data(url):
    try:
        # Fetch data from the API
        response = requests.get(url)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx and 5xx)
        data = response.json()

        # Extract relevant data
        heroes = []
        for item in data.get('items', []):
            jsonItem = item.get('item', {})
            jsonItemAdditionalFields = jsonItem.get('additionalFields', {})
            hero_bio_url = jsonItemAdditionalFields.get('heroBioURL', 'N/A')
            hero_name = jsonItemAdditionalFields.get('heroName', 'N/A').strip()  # Trim spaces

            print(f"Fetching data for: {hero_name}...")

            hero_data = fetch_hero_data(hero_bio_url) if hero_bio_url != 'N/A' else 'Description not available'
            hero_description = hero_data['description']
            hero_links = hero_data['links']

            hero = {
                "id": jsonItem.get('id', 'N/A'),
                "name": hero_name,
                "heroSinceDate": jsonItemAdditionalFields.get('heroSinceDate', 'N/A'),
                "description": hero_description,
                "heroBioURL": hero_bio_url,
                "hero_links": hero_links,
                "heroCategory": jsonItemAdditionalFields.get('heroCategory', 'N/A'),
                "heroImageURL": jsonItemAdditionalFields.get('heroImageURL', 'N/A'),
                "heroLocation": jsonItemAdditionalFields.get('heroLocation', 'N/A'),
            }
            heroes.append(hero)
            # Wait for 200ms before the next request to not bruteforce webserver
            time.sleep(0.2)

        return heroes
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return []

def fetch_hero_data(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'lxml')
        
        # XPath
        # /html/body/div[2]/main/div[2]/div/div/div[1]/div[2]/div
        # Extract content from the specified path
        main_content = soup.select('main#aws-page-content-main')[0]

        paragraphs = main_content.findAll('div')[9].findAll('p')
        # Join the text from all <p> tags, separated by '\n\n\n'
        text = '\n\n\n'.join([p.get_text().strip() for p in paragraphs])

        ascii_description = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('ascii')

        # Extract links from the specified div
        links = main_content.findAll('div')[6].find_all('a', class_='lb-txt')
        links_data = []
        for link in links:
            url = link.get('href', 'No URL')
            text = link.get_text(strip=True) or link.find('img').get('alt', 'No Text')
            links_data.append({"text": text.strip(), "url": url})

        return {
            "description": ascii_description if ascii_description else 'Description not found',
            "links": links_data
        }
    except requests.exceptions.RequestException as e:
        return f"Failed to fetch description: {e}"
    except Exception as e:
        return f"An error occurred while parsing the description: {e}"

def main():
    heroes_data = fetch_aws_heroes_data(url)
    
    # Escape unescaped quotes and save the data to a JSON file
    with open('aws_heroes.json', 'w', encoding='utf-8') as file:
        json.dump(heroes_data, file, indent=4, ensure_ascii=False)
    
    print(f"Data saved to aws_heroes.json. Total heroes scraped: {len(heroes_data)}")


if __name__ == "__main__":
    main()