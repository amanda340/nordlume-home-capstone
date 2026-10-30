/**
 * Thin HTTP client wrapping the Nordlume Catalog API's GET /orders/{orderNumber}/shipments
 * endpoint via the Nordlume_Catalog_API Named Credential. Kept as its own class (rather than
 * inlined in an invocable method) so callouts can be intercepted with HttpCalloutMock in tests.
 */
public with sharing class OrderShipmentClient {

    public class ShipmentInfo {
        public String orderNumber;
        public String status;
        public Date estimatedDeliveryDate;
        public List<String> skus;
    }

    /**
     * Calls the mock-api shipment endpoint for the given order number.
     * Returns null when the API responds 404 (unknown order number) or any other
     * non-2xx/unparseable response -- callers should treat null as "no shipment info available".
     */
    public static ShipmentInfo getShipment(String orderNumber) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Nordlume_Catalog_API/orders/' + EncodingUtil.urlEncode(orderNumber, 'UTF-8') + '/shipments');
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            return null;
        }

        return parseShipment(response.getBody());
    }

    @TestVisible
    private static ShipmentInfo parseShipment(String jsonBody) {
        if (String.isBlank(jsonBody)) {
            return null;
        }

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        ShipmentInfo info = new ShipmentInfo();
        info.orderNumber = (String) parsed.get('orderNumber');
        info.status = (String) parsed.get('status');

        Object rawDate = parsed.get('estimatedDeliveryDate');
        if (rawDate != null) {
            info.estimatedDeliveryDate = Date.valueOf((String) rawDate);
        }

        info.skus = new List<String>();
        Object rawSkus = parsed.get('skus');
        if (rawSkus instanceof List<Object>) {
            for (Object sku : (List<Object>) rawSkus) {
                info.skus.add((String) sku);
            }
        }

        return info;
    }
}
