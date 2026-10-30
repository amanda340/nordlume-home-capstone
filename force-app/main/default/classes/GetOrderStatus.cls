/**
 * Retrieves order status for a verified customer. The caller MUST supply a
 * verifiedContactId that came from VerifyIdentity's result -- never a raw id taken from
 * conversation text -- so every query below is scoped to that contact.
 *
 * - Without orderNumber: lists recent Orders scoped by CustomerAuthorizedById.
 * - With orderNumber: looks up that single Order scoped by the SAME CustomerAuthorizedById, so an
 *   existing-but-other-customer's order yields the identical NOT_FOUND outcome as a
 *   nonexistent order number (never leaks existence). On a match, fetches OrderItems and calls
 *   the mock-api shipment endpoint (via OrderShipmentClient) for live status + ETA. Shipment
 *   status is never persisted back onto the Order record.
 */
public with sharing class GetOrderStatus {

    private static final Integer RECENT_ORDERS_LIMIT = 10;

    @InvocableMethod(
        label='Get Order Status'
        description='Lists a verified customer\'s recent orders, or looks up one order by number (scoped to that same verified customer) including live shipment status.'
        category='Nordlume Home Advisor'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            responses.add(executeOne(request));
        }

        return responses;
    }

    private static Response executeOne(Request request) {
        Response response = new Response();
        response.orders = new List<OrderResult>();

        if (request.verifiedContactId == null) {
            response.found = false;
            return response;
        }

        if (String.isBlank(request.orderNumber)) {
            return listRecentOrders(request.verifiedContactId, response);
        }

        return lookupSingleOrder(request.verifiedContactId, request.orderNumber, response);
    }

    private static Response listRecentOrders(Id verifiedContactId, Response response) {
        List<Order> orders = [
            SELECT OrderNumber, Status, EffectiveDate
            FROM Order
            WHERE CustomerAuthorizedById = :verifiedContactId
            WITH USER_MODE
            ORDER BY EffectiveDate DESC
            LIMIT :RECENT_ORDERS_LIMIT
        ];

        for (Order order : orders) {
            OrderResult result = new OrderResult();
            result.orderNumber = order.OrderNumber;
            result.status = order.Status;
            response.orders.add(result);
        }

        response.found = !orders.isEmpty();
        return response;
    }

    private static Response lookupSingleOrder(Id verifiedContactId, String orderNumber, Response response) {
        List<Order> matches = [
            SELECT Id, OrderNumber
            FROM Order
            WHERE CustomerAuthorizedById = :verifiedContactId
            AND OrderNumber = :orderNumber
            WITH USER_MODE
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            response.found = false;
            return response;
        }

        Order matchedOrder = matches[0];

        // Deliberately no WITH USER_MODE here: OrderItem has no independent object/field
        // permissions in Salesforce's security model -- access to order products is always
        // derived from access to the parent Order (confirmed empirically: ObjectPermissions
        // has zero rows for OrderItem across every profile/permission set in this org,
        // including System Administrator, and WITH USER_MODE throws
        // "System.QueryException: sObject type 'OrderItem' is not supported" for ANY user,
        // regardless of permission grants, because the enforcement engine has no CRUD/FLS
        // entry to evaluate for this sObject type). The Order lookup above already enforced
        // WITH USER_MODE + CustomerAuthorizedById scoping for this same verified contact, so
        // querying this Order's OrderItems without WITH USER_MODE does not widen access.
        List<OrderItem> items = [
            SELECT Quantity, Product2.SKU__c, Product2.Name
            FROM OrderItem
            WHERE OrderId = :matchedOrder.Id
        ];

        OrderResult result = new OrderResult();
        result.orderNumber = matchedOrder.OrderNumber;
        result.itemsSummary = buildItemsSummary(items);

        OrderShipmentClient.ShipmentInfo shipment = OrderShipmentClient.getShipment(matchedOrder.OrderNumber);
        if (shipment != null) {
            result.status = shipment.status;
            result.estimatedDeliveryDate = shipment.estimatedDeliveryDate;
        }

        response.orders.add(result);
        response.found = true;
        return response;
    }

    private static String buildItemsSummary(List<OrderItem> items) {
        List<String> parts = new List<String>();

        for (OrderItem item : items) {
            String sku = item.Product2 != null ? item.Product2.SKU__c : null;
            String name = item.Product2 != null ? item.Product2.Name : null;
            parts.add((name != null ? name : sku) + ' x' + Integer.valueOf(item.Quantity));
        }

        return String.join(parts, ', ');
    }

    public class Request {
        @InvocableVariable(label='Verified Contact Id' description='The contact id returned by VerifyIdentity. Must never be populated directly from raw conversation text.' required=true)
        public Id verifiedContactId;

        @InvocableVariable(label='Order Number' description='Optional. When omitted, recent orders for the verified contact are listed instead.')
        public String orderNumber;
    }

    public class Response {
        @InvocableVariable(label='Found' description='False when no order(s) matched the verified contact (and, if supplied, the order number).')
        public Boolean found;

        @InvocableVariable(label='Orders' description='Matching order(s). Empty when nothing was found.')
        public List<OrderResult> orders;
    }

    public class OrderResult {
        @InvocableVariable(label='Order Number')
        public String orderNumber;

        @InvocableVariable(label='Status' description='Native Order status when listing recent orders; live shipment status from the mock-api when a single order was looked up.')
        public String status;

        @InvocableVariable(label='Estimated Delivery Date')
        public Date estimatedDeliveryDate;

        @InvocableVariable(label='Items Summary' description='Human-readable "Name x Quantity" summary of the order\'s line items. Only populated for a single-order lookup.')
        public String itemsSummary;
    }
}
