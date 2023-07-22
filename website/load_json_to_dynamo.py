import boto3
import json
f = open('services_app_store.json')
data = json.load(f)
dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('AWSary-services')

for i in data:
    print("Saving: " + i['name'])
    table.put_item(Item=i)

f.close()