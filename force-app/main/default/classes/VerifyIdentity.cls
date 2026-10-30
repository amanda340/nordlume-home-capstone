/**
 * Verifies a caller's identity against an existing Order before any order details
 * are disclosed. Always returns a neutral "not found" response (verifiedContactId = null)
 * whether the order number doesn't exist OR exists but belongs to a different customer's
 * email -- the two cases must be indistinguishable to the caller.
 */
public with sharing class VerifyIdentity {

    @InvocableMethod(
        label='Verify Customer Identity'
        description='Verifies an order number and email match an existing order. Returns a verified contact id only on a match; never reveals whether an order exists for a different customer.'
        category='Nordlume Home Advisor'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            responses.add(verifyOne(request));
        }

        return responses;
    }

    private static Response verifyOne(Request request) {
        Response response = new Response();
        response.verifiedContactId = null;

        if (String.isBlank(request.orderNumber) || String.isBlank(request.email)) {
            return response;
        }

        List<Order> matches = [
            SELECT CustomerAuthorizedById
            FROM Order
            WHERE OrderNumber = :request.orderNumber
            AND CustomerAuthorizedBy.Email = :request.email
            WITH USER_MODE
            LIMIT 1
        ];

        if (!matches.isEmpty()) {
            response.verifiedContactId = matches[0].CustomerAuthorizedById;
        }

        return response;
    }

    public class Request {
        @InvocableVariable(label='Order Number' description='The order number provided by the customer.' required=true)
        public String orderNumber;

        @InvocableVariable(label='Email' description='The email address provided by the customer.' required=true)
        public String email;
    }

    public class Response {
        @InvocableVariable(label='Verified Contact Id' description='Populated only when the order number and email match an existing order. Null means "not verified" -- do not distinguish between a nonexistent order and a mismatched email.')
        public Id verifiedContactId;
    }
}
