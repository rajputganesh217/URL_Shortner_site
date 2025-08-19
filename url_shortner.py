# url shorten code. This is the code that will be called when the user wants to shorten a URL.


import json
import boto3
import hashlib

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('url_shortner')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    long_url = body.get('long_url')

    f not long_url:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing long_url"})
        }

    # Generate short ID
    short_id = hashlib.sha256(long_url.encode()).hexdigest()[:6]

    # Store in DynamoDB
    table.put_item(Item={"short_id": short_id, "long_url": long_url})

    short_url = f"https://your-api-gateway-url/{short_id}"

    return {
        "statusCode": 200,
        "body": json.dumps({"short_url": short_url})
    }
