#!/usr/bin/python
from __future__ import print_function
import time
import boto3
import sys

def main():
    
    s3_file = sys.argv[1]

    s3 = boto3.client('s3')
    bucket = "lyle2audio"

    #Download file
    s3.download_file(bucket, s3_file,s3_file)


    response = s3.delete_object(
        Bucket=bucket,
        Key=s3_file
    )

if __name__ == '__main__':
    main()