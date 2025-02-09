import boto3

iam = boto3.client('iam')


def lambda_handler(event, context):
    """Triggered by GuardDuty, extracts username and disables access key"""
    try:
        username = event["detail"]["resource"]["accessKeyDetails"]["userName"]
        hacked_key = event["detail"]["resource"]["accessKeyDetails"]["accessKeyId"]

        iam.update_access_key(UserName=username, AccessKeyId=hacked_key, Status='Inactive')

        print("Detected access key from Kali machine. Key was disabled successfully. "
              f"\nAccess Key: {hacked_key} \nUsername: {username}\n-")

    except Exception as e:
        print(f"Error processing event: {str(e)}")

    return {"status": "success"}
