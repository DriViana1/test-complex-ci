FROM node:14.4.0-alpine

WORKDIR "/app"

COPY package-lock.json ./

RUN npm install

COPY . .

CMD ["npm", "run", "start"]