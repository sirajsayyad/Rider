const AWS = require('aws-sdk');
const express = require('express');

const app = express();
app.use(express.json());

AWS.config.update({
    region: 'ap-south-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY

});

const dynamo = new AWS.DynamoDB.DocumentClient();






app.get('/test', async (req, res) => {
    try {
        const params = {
            TableName: 'users'
        };

        const data = await dynamo.scan(params).promise();

        res.json({
            message: "AWS Connected Successfully ✅",
            data: data.Items
        });

    } catch (error) {
        res.json({
            message: "Error ❌",
            error: error
        });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});