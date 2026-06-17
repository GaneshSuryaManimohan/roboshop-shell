#!/bin/bash

set -e
failure(){
    echo "Error on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

USERID=$(id -u)
TIME_STAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILURE $N"
        exit 1
    else
        echo -e "$2....$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script as super user"
    exit 1
else
    echo "Running the script as super user"
fi

dnf install maven -y &>>$LOGFILE
VALIDATE $? "Installing maven package"

if ! id roboshop &>>$LOGFILE
then
    echo "Creating 'roboshop' user"
    useradd roboshop &>>$LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "User 'roboshop' already exists... $Y SKIPPING $N " | tee -a $LOGFILE
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>>$LOGFILE
VALIDATE $? "Downloading shipping code"

cd /app &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

unzip -o /tmp/shipping.zip &>>$LOGFILE
VALIDATE $? "Extracting shipping code"

mvn clean package &>>$LOGFILE
VALIDATE $? "Building shipping code"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE
VALIDATE $? "Renaming shipping jar file"

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>>$LOGFILE
VALIDATE $? "Copying shipping.service to systemd"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable shipping &>>$LOGFILE
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>>$LOGFILE
VALIDATE $? "Starting shipping service"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql client"

if [ -f /app/schema_loaded ]
then
    echo -e "MySQL schema/data for shipping already loaded...$Y SKIPPING $N" | tee -a $LOGFILE
else
    mysql -h mysql.surya-devops.online -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGFILE
    VALIDATE $? "Installing mysql schema for shipping service"

    mysql -h mysql.surya-devops.online -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOGFILE
    VALIDATE $? "Installing mysql app user for shipping service"

    mysql -h mysql.surya-devops.online -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGFILE
    VALIDATE $? "Installing mysql master data for shipping service"

    touch /app/schema_loaded
fi

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restarting shipping service"