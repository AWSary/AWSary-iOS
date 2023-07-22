import boto3
import json

dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('AWSary-services')

response = table.scan()
items = response['Items']

# export items to new_openai_services_app_store.json
with open('new_openai_services_app_store.json', 'w') as outfile:
    json.dump(items, outfile, indent=4, default=str)