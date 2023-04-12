import json
import boto3
import os

sns = boto3.client('sns')

def lambda_handler(event, context):
    
    #Extract details from JSON event
    detailType= event["detail-type"]
    region = event["region"]
    accountId = event["account"] 
     
    #AWS API Call via CloudTrail finding
    if (detailType == "AWS API Call via CloudTrail"):
        
        time = event["detail"]["eventTime"]
        eventName = event["detail"]["eventName"]
        requestParameters = event["detail"]["requestParameters"]
        # requestParameters = event["detail"]["items"]["resourceType"]

        #Extract user details from the CloudTrail event
        userIdentity = event['detail']['userIdentity']
        userName = userIdentity.get('userName')
        userArn = userIdentity.get('arn')      
        
        userArnParts = userArn.split('/')
        userNameFromArn = userArnParts[-1] if len(userArnParts) > 1 else 'unknown'
        
        message = f"An User {userNameFromArn} has performed {eventName} in account {accountId} at time {time} in region {region} \n {requestParameters}"
        

        
        
    #If the event doesn't match any of the above, return the event    
    else:
        message = str(event)

    topic_arn = os.environ['SNS_TOPIC_ARN']
    response = sns.publish(
            TopicArn = topic_arn,
            Message = message
            )
    
    
    return {
      'statusCode': 200,
      'body': json.dumps('Success!')
}
