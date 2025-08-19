
---

# AWS Serverless URL Shortener

This is a simple URL shortening service built using **AWS Lambda**, **API Gateway**, **DynamoDB**, and optionally **S3** for static website hosting. The infrastructure is deployed and managed with **Terraform**.

## Features

* Shorten long URLs into short, shareable links
* Store shortened URLs in **DynamoDB**
* Redirect short URLs to original long URLs via **API Gateway + Lambda**
* Optional static frontend hosted in **S3**
* Infrastructure deployment automated with **Terraform**

## Architecture

* **Lambda Functions**:

  * `url_shortener`: Handles URL shortening
  * `url_redirect`: Handles redirecting short URLs
* **DynamoDB**: Stores mapping between `short_id` and `long_url`
* **API Gateway**: Exposes endpoints for shortening URLs and redirecting
* **S3 (optional)**: Hosts the frontend HTML page
* **Terraform**: Automates creation of DynamoDB table, Lambda, API Gateway, and optional S3 bucket

## Prerequisites

* **AWS CLI** configured with necessary permissions
* **Terraform** installed
* IAM permissions to manage Lambda, API Gateway, DynamoDB, and optionally S3

## Setup Instructions

1. **Clone the repository**

```sh
git clone <your-repo-url>
cd <your-repo-folder>
```

2. **Deploy Infrastructure with Terraform**

```sh
terraform init
terraform apply -auto-approve
```

This will create:

* DynamoDB table (`url_shortner`)
* Lambda functions (`url_shortener`, `url_redirect`)
* API Gateway endpoints
* IAM roles & policies

3. **Deploy Lambda function code**

```sh
zip lambda_function.zip url_shortner.py
aws lambda update-function-code --function-name url_shortener --zip-file fileb://lambda_function.zip
```

(Repeat for `url_redirect.py` if needed.)

4. **Test API Gateway Endpoint**

```sh
# Shorten a URL
curl -X POST "https://<your-api-gateway-url>/shorten" \
     -H "Content-Type: application/json" \
     -d '{"long_url": "https://example.com"}'
     
# Access a shortened URL (replace <short_id> with actual ID)
curl -v "https://<your-api-gateway-url>/<short_id>"
```

5. **Optional: Host Frontend on S3**

* Upload `index.html` to the S3 bucket created by Terraform (if enabled)
* Enable static website hosting and make the bucket public
* Update the `<API_GATEWAY_URL>` in your `index.html` JavaScript to point to your API

## Common Errors & Fixes

### 1. **Failed to Fetch / CORS Issues**

* Ensure **CORS** is enabled for your API Gateway POST endpoint
* Configure:

  * `Access-Control-Allow-Origin: *`
  * `Access-Control-Allow-Headers: Content-Type`
  * `Access-Control-Allow-Methods: POST, GET`

### 2. **DynamoDB Table Not Found**

* Confirm the table name in your Lambda function matches DynamoDB

```python
table = dynamodb.Table('url_shortner')
```

* Redeploy Lambda after changes

### 3. **Access Denied**

* Ensure Lambda role has correct permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:PutItem",
    "dynamodb:GetItem"
  ],
  "Resource": "arn:aws:dynamodb:<region>:<account-id>:table/url_shortner"
}
```

### 4. **Incorrect API URL**

* Use the API endpoint from Terraform output:

```sh
terraform output api_endpoint
```

* Replace any hard-coded URL in `index.html` with this endpoint

## Conclusion

This serverless URL shortener provides a **fast, scalable, and fully AWS-managed solution** for shortening URLs. Using Terraform ensures the infrastructure can be recreated or updated easily.

Once deployed, users can:

* Visit the static site (if hosted on S3)
* Enter a URL to shorten
* Copy the generated short URL
* Share it; it will redirect to the original URL via API Gateway + Lambda

---


