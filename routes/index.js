const bodyParser = require("body-parser"),
      express = require("express"),
      {getmysqlpool} = require("../modules/mysqlpool"),
      router = express.Router(),
      util = require("util");

function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}

router.get("/", (req, res) => {
    res.render("home", {
        "pageName": "Home"
    });
});

router.get("/contact", (req, res) => {
    res.render("contact", {
        "pageName": "Contact"
    });
});

router.post("/contact", (req, res) => {
    const firstName = req["body"]["contact"]["firstName"];
    const lastName = req["body"]["contact"]["lastName"];
    const sourceEmail = req["body"]["contact"]["email"];
    const message = req["body"]["contact"]["message"];
    const insertSql = `INSERT INTO Contacts (FirstName,LastName,Email,Message) VALUES ('${firstName}', '${lastName}', '${sourceEmail}', '${message}')`;
    if (firstName.length >= 2 &&
        firstName.length <= 35 &&
        lastName.length >= 2 &&
        lastName.length <= 35 &&
        (validateEmail(sourceEmail)) &&
        message.length <= 10000) {
            console.log(insertSql);
            getmysqlpool().then((pool) => {
                pool.query(insertSql, (error, results, fields) => {
                    if (error) throw error;
                });
            });        
            return res.render("thanks", {
                "pageName": "Contact"
            });
    }
})

module.exports = router;
