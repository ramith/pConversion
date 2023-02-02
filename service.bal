import ballerinax/exchangerates;
import ramith/countryprofile;
import ballerina/log;
import ballerina/http;
import ballerina/time;

configurable string exchangeRateAPIKey = ?;
configurable string clientSecret = ?;
configurable string clientId = ?;

type PricingInfo record {
    string currencyCode;
    string displayName;
    decimal amount;
    string validUntil;
};

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function get convert(decimal amount = 1, string target = "AUD", string base = "USD") returns PricingInfo|error {

        log:printInfo("new request", amount = amount);
        countryprofile:Client countryprofileEp = check new (config = {
            auth: {
                clientId: clientId,
                clientSecret: clientSecret
            }
        });
        countryprofile:Currency getCurrencyCodeResponse = check countryprofileEp->getCurrencyCode(code = target);
        exchangerates:Client exchangeratesEp = check new ();
        exchangerates:CurrencyExchangeInfomation getExchangeRateForResponse = check exchangeratesEp->getExchangeRateFor(apikey = exchangeRateAPIKey, baseCurrency = base);

        decimal exchangeRate = <decimal>getExchangeRateForResponse.conversion_rates[target];
        decimal convertedAmount = amount * exchangeRate;

        time:Utc validUntil = time:utcAddSeconds(time:utcNow(), 3600);

        PricingInfo pricingInfo = {
            currencyCode: target,
            displayName: getCurrencyCodeResponse.displayName,
            amount: convertedAmount,
            validUntil: time:utcToString(validUntil)
        };

        return pricingInfo;
    }
}
