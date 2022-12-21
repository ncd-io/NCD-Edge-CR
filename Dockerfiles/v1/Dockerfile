From nodered/node-red:3.0.0-18

#Users should be sure to pass in a port to use for Node-Red
#EXPOSE 1880

#recommended setting test without and then test with
#ENV NODE_ENV=production

#set working directory to ~/.node-red to install all packages necessary there
WORKDIR ~/.node-red

RUN npm install ncd-red-wireless-2
RUN npm install node-red-dashboard
