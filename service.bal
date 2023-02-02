import ballerinax/exchangerates;
import ramith/countryprofile;
import ballerina/log;
import ballerina/http;
import ballerina/time;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string currencyExchangeAPIKey = ?;

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


        log:printInfo("convertion request", baseCurrency = base, targetCurrency = target, amount = amount);

        countryprofile:Client countryprofileEp = check new (config = {
            auth: {
                clientId: clientId,
                clientSecret: clientSecret
            }
        });
        countryprofile:Currency targetCurrencyInfo = check countryprofileEp->getCurrencyCode(code = base);
        exchangerates:Client baseClient = check new ();
        exchangerates:CurrencyExchangeInfomation rate = check baseClient->getExchangeRateFor(currencyExchangeAPIKey, base);

        decimal exchangeRate = <decimal>rate.conversion_rates[target];
        time:Utc validUntil = time:utcAddSeconds(time:utcNow(), 3600 * 60);

        PricingInfo pricingInfo = {
            displayName: targetCurrencyInfo.displayName,
            currencyCode: target,
            amount: exchangeRate * amount,
            validUntil: time:utcToString(validUntil)

        };
        return pricingInfo;
    }
}
