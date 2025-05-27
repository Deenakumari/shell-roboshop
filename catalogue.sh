#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R Error: please run this script as root access $N" | tee -a $LOG_FILE
else
    echo "you are in root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
       echo -e "$2 is .... $G SUCCESS $N" | tee -a $LOG_FILE
    else
       echo -e "$2 is .... $R failure $N" | tee -a $LOG_FILE
       exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs:20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "creating roboshop system user"

mkdir /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading catalogue"

cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping the catalogue"

cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "installing dependices"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb client"

mongosh --host mangodb.deena.fun </app/db/master-data.js &>>$LOG_FILE


