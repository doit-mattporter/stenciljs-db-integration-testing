const {auth} = require('google-auth-library'),
      {execSync} = require("child_process"),
      {SecretManagerServiceClient} = require("@google-cloud/secret-manager"),
      mysql = require("mysql");

const gcp_secret_client = new SecretManagerServiceClient();

async function getContactFormUserPasswordSecret() {
    const projectId = await auth.getProjectId();
    // Oddly enough, the following is the only way GCP exposes projectNumber, and secret manager is the only place I've seen projectNumber used within a resourceID
    const projectNumber = execSync(`gcloud projects list --filter="${projectId}" --format="value(PROJECT_NUMBER)"`).toString().replace("\n", "");
    const [contact_form_write_password] = await gcp_secret_client.accessSecretVersion({
        name: `projects/${projectNumber}/secrets/wfe-mysql-contact-user/versions/latest`
    });
    return contact_form_write_password.payload.data.toString();
};

const password = getContactFormUserPasswordSecret().then((result) => {
    return result.replace("\n", "");
});

async function getMysqlHostIp() {
    const projectId = await auth.getProjectId();
    // There is no GCP NodeJS package for Cloud SQL, must use gcloud
    const ipArray = execSync(`gcloud sql instances describe wfe-mysql --project ${projectId} --format 'value(ipAddresses.ipAddress)'`).toString().replace("\n", "").split(";")
    // const ipAddress = ipArray.pop(); // If only a public or priate IP is available, will return this. If both are available, returns the private IP.
    const ipAddress = ipArray[0]; // If only a public or priate IP is available, will return this. If both are available, returns the private IP.
    return ipAddress;
}

const mysqlHostIp = getMysqlHostIp().then((result) => {
    return result;
});

async function getMysqlPool() {
    return mysql.createPool({
        connectionLimit: 10,
        host: await mysqlHostIp,
        // host: "10.52.80.3",
        port: 3306,
        user: "contact_form_write_user",
        password: await password,
        // password: "ZWM2NjU5ZTUwMzM1MDU0MDZjODQ0MmUy",
        database: "contactdb"
    });
};

module.exports.getMysqlPool = getMysqlPool;
