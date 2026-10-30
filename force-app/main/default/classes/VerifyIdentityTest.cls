@isTest
private class VerifyIdentityTest {

    @TestSetup
    static void setup() {
        Account account = new Account(Name = 'Nordlume Customers');
        insert account;

        Contact astrid = new Contact(FirstName = 'Astrid', LastName = 'Lindgren', Email = 'astrid.lindgren@example.com', AccountId = account.Id);
        Contact erik = new Contact(FirstName = 'Erik', LastName = 'Johansson', Email = 'erik.johansson@example.com', AccountId = account.Id);
        insert new List<Contact>{ astrid, erik };

        Order astridOrder = new Order(
            AccountId = account.Id,
            CustomerAuthorizedById = astrid.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert astridOrder;
    }

    @isTest
    static void testVerifiedMatchReturnsContactId() {
        Order order = [SELECT OrderNumber, CustomerAuthorizedById FROM Order LIMIT 1];
        Contact contact = [SELECT Email FROM Contact WHERE Id = :order.CustomerAuthorizedById];

        VerifyIdentity.Request request = new VerifyIdentity.Request();
        request.orderNumber = order.OrderNumber;
        request.email = contact.Email;

        Test.startTest();
        List<VerifyIdentity.Response> responses = VerifyIdentity.execute(new List<VerifyIdentity.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(order.CustomerAuthorizedById, responses[0].verifiedContactId, 'Matching order number + email should return the contact id');
    }

    @isTest
    static void testNonexistentOrderNumberReturnsNeutralResponse() {
        VerifyIdentity.Request request = new VerifyIdentity.Request();
        request.orderNumber = 'NO-SUCH-ORDER';
        request.email = 'astrid.lindgren@example.com';

        List<VerifyIdentity.Response> responses = VerifyIdentity.execute(new List<VerifyIdentity.Request>{ request });

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].verifiedContactId, 'Unknown order number must yield a neutral null result');
    }

    @isTest
    static void testOtherCustomersOrderReturnsIdenticalNeutralResponse() {
        Order order = [SELECT OrderNumber FROM Order LIMIT 1];

        VerifyIdentity.Request request = new VerifyIdentity.Request();
        request.orderNumber = order.OrderNumber;
        request.email = 'erik.johansson@example.com';

        List<VerifyIdentity.Response> wrongCustomerResponses = VerifyIdentity.execute(new List<VerifyIdentity.Request>{ request });

        VerifyIdentity.Request nonexistentRequest = new VerifyIdentity.Request();
        nonexistentRequest.orderNumber = 'NO-SUCH-ORDER';
        nonexistentRequest.email = 'erik.johansson@example.com';

        List<VerifyIdentity.Response> nonexistentResponses = VerifyIdentity.execute(new List<VerifyIdentity.Request>{ nonexistentRequest });

        System.assertEquals(null, wrongCustomerResponses[0].verifiedContactId, 'An existing order belonging to a different customer must not verify');
        System.assertEquals(
            wrongCustomerResponses[0].verifiedContactId,
            nonexistentResponses[0].verifiedContactId,
            'Wrong-customer and nonexistent-order responses must be identical (both null)'
        );
    }

    @isTest
    static void testBlankInputsReturnNeutralResponse() {
        VerifyIdentity.Request request = new VerifyIdentity.Request();
        request.orderNumber = '';
        request.email = '';

        List<VerifyIdentity.Response> responses = VerifyIdentity.execute(new List<VerifyIdentity.Request>{ request });

        System.assertEquals(null, responses[0].verifiedContactId);
    }
}
