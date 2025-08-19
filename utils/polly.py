import boto3

dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('AWSary-services')
polly_client = boto3.client('polly')

response = table.scan()
items = response['Items']

for item in items:
    print("Start working on: " + item['name'])
    service_name = item['longName']
    response = polly_client.synthesize_speech(VoiceId='Brian', OutputFormat='mp3', Text=service_name)

    filename = 'speech/' + item['name'].replace(' ','_') + '_Brian_' + 'en-GB' + '.mp3'
    with open(filename, 'wb') as file:
        file.write(response['AudioStream'].read())
    print("Done with: " + item['name'])
    
