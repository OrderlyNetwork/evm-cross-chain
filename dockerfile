# hardhat docker file
#
FROM node:16-alpine

# copy everything to the container
COPY . /app

# set the working directory
WORKDIR /app

# install dependencies
RUN npm install

# run npx hardhat mockCrossChain
CMD ["npx", "hardhat", "mockCrossChain"]