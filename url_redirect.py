# redirect function this is the function that will be called when the short URL is accessed 
import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('url_shortner') 

def lambda_handler(event, context):
    short_id = event['pathParameters']['short_id']

    response = table.get_item(Key={'short_id': short_id})

    if 'Item' not in response:
        return {
            "statusCode": 404,
            "body": json.dumps({"error": "Short URL not found"})
        }

    long_url = response['Item']['long_url']

    return {
        "statusCode": 302,
        "headers": {"Location": long_url}
    }
