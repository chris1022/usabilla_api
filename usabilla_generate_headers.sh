#!/bin/bash
##########################################################################################
#Author: Alexander Vellekoop                                                             #
#Date: January 3 2018                                                                    #
#Description: Generates the Authentication and Date header for the Usabilla API          #
##########################################################################################
join_by() { 
	local IFS="$1"
	shift 
	printf "$*"
}
sha256_hash_in_hex(){
  DATA="$@"
  printf "$DATA" | openssl dgst -sha256 | sed -e 's/^.* //'
}
hex_of_sha256_hmac_with_string_key_and_value {
  KEY="$1"
  DATA="$2"
  shift 2
  printf "$DATA" | openssl dgst -sha256 -hmac "$KEY" | sed -e 's/^.* //'
}
hex_of_sha256_hmac_with_hex_key_and_value {
  KEY="$1"
  DATA="$2"
  shift 2
  printf "$DATA" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$KEY" | sed -e 's/^.* //'
}

#Initialize variables
accessKey='accessKey'
secretKey='secretKey'
host='host:data.usabilla.com'
#Insert usabilla uri
uri='/live/websites/campaign/*/results'
method='GET'
algorithm='USBL1-HMAC-SHA256'
short_date=$(date +%Y%m%d)
long_date=$(date +%Y%m%dT%H%M%SZ)
credentialScope=$short_date'/usbl1_request'
#Encode wildcard asterisk
uri=$(echo $uri | sed -e "s/*/%%2A/g")
queryParameters=''
canonicalHeaders=$host'\nx-usbl-date:'$long_date'\n'
signedHeaders='host;x-usbl-date'
requestPayload=$(sha256_hash_in_hex)

#Create Canonical String
canonicalString=$method'\n'$uri'\n'$queryParameters'\n'$canonicalHeaders'\n'$signedHeaders'\n'$requestPayload
hashedCanonicalString=$(sha256_hash_in_hex $canonicalString)

#Create string to Sign
stringToSign=$algorithm'\n'$long_date'\n'$credentialScope'\n'$hashedCanonicalString

#Create signature
kDate=$(hex_of_sha256_hmac_with_string_key_and_value "USBL1$secretKey" "$short_date")
kSigning=$(hex_of_sha256_hmac_with_hex_key_and_value "$kDate" "usbl1_request")
signature=$(hex_of_sha256_hmac_with_hex_key_and_value "$kSigning" "$stringToSign")

#Generate headers
authorizationHeader=$(join_by , $algorithm 'Credential='$accessKey'/'$short_date'/usbl1_request' 'SignedHeaders='$signedHeaders 'Signature='$signature)
dateHeader=$long_date

printf $authorizationHeader
printf $dateHeader
