import openai

openai.api_key = "YOUR_API_KEY"

import boto3
import json

dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('AWSary-services')

# for each objet in table, get the full object fromy dynamo, then query openai for the name
# and save the result in dynamo

response = table.scan()
items = response['Items']

for item in items:
    print("Start working on: " + item['name'])
    if "#" not in item['shortDesctiption'] :
        print("Checking OpenAIn for : " + item['name'])
        chat_completion = openai.ChatCompletion.create(model="gpt-4", temperature=1, max_tokens=512,top_p=1,frequency_penalty=0,presence_penalty=0,messages=[{"role": "system", "content": "You are an AWS instructor and want to teach you students about AWS services.You will describe a macro overview about the service you are asked for, and then a little resume about pricing as well as some interesting facts.Use Markdown to make your output more organized, specifically create a title with # for each major topic. Include sections with titles 'Overview', 'Pricing' and 'Interesting Facts'."},{"role": "user", "content": item['name']}])
        item['shortDesctiption'] = chat_completion.choices[0].message.content
        table.put_item(Item=item)
    else:
        print("Item already had openAI description : " + item['name'])
