# Use the official AWS CLI Docker image as the base image
FROM ubuntu:22.04

# Set the working directory
WORKDIR /app

# Set environment variable
ENV DEBIAN_FRONTEND=noninteractive
ENV ACTIVITY_SUB_TASK_CODE=AWS_IAM_USER_CREATOR

# Install required packages
RUN apt update -y && \
    apt install -y awscli jq gettext mailutils postfix && \
    apt clean all && \
    rm -rf /var/cache/apt

# Copy your scripts into the container
COPY build.sh .
COPY BP-BASE-SHELL-STEPS BP-BASE-SHELL-STEPS

# Set execute permissions for the scripts
RUN chmod +x build.sh BP-BASE-SHELL-STEPS/* 


# Set the entry point for the Docker container
ENTRYPOINT ["./build.sh"]
