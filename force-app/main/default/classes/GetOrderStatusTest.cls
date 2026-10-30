@isTest
private class GetOrderStatusTest {

    private class ShipmentMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(
                '{"orderNumber":"NH-1001","status":"SHIPPED","estimatedDeliveryDate":"2026-11-05","skus":["SOF-N001"]}'
            );
            return response;
        }
    }

    private class NotFoundShipmentMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(404);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"error":"NOT_FOUND"}');
            return response;
        }
    }

    @TestSetup
    static void setup() {
        Account account = new Account(Name = 'Nordlume Customers');
        insert account;

        Contact astrid = new Contact(FirstName = 'Astrid', LastName = 'Lindgren', Email = 'astrid.lindgren@example.com', AccountId = account.Id);
        Contact erik = new Contact(FirstName = 'Erik', LastName = 'Johansson', Email = 'erik.johansson@example.com', AccountId = account.Id);
        insert new List<Contact>{ astrid, erik };

        Product2 sofa = new Product2(Name = 'Fjord Modular Sofa', SKU__c = 'SOF-N001', IsActive = true);
        insert sofa;

        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = sofa.Id,
            UnitPrice = 1299,
            IsActive = true
        );
        insert entry;

        Order order1 = new Order(
            AccountId = account.Id,
            CustomerAuthorizedById = astrid.Id,
            Pricebook2Id = standardPricebookId,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        Order order2 = new Order(
            AccountId = account.Id,
            CustomerAuthorizedById = astrid.Id,
            Pricebook2Id = standardPricebookId,
            EffectiveDate = Date.today().addDays(-1),
            Status = 'Draft'
        );
        Order otherCustomerOrder = new Order(
            AccountId = account.Id,
            CustomerAuthorizedById = erik.Id,
            Pricebook2Id = standardPricebookId,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert new List<Order>{ order1, order2, otherCustomerOrder };

        insert new OrderItem(
            OrderId = order1.Id,
            Product2Id = sofa.Id,
            PricebookEntryId = entry.Id,
            Quantity = 1,
            UnitPrice = 1299
        );
    }

    @isTest
    static void testListRecentOrdersScopedToVerifiedContact() {
        Contact astrid = [SELECT Id FROM Contact WHERE LastName = 'Lindgren' LIMIT 1];

        GetOrderStatus.Request request = new GetOrderStatus.Request();
        request.verifiedContactId = astrid.Id;

        Test.startTest();
        List<GetOrderStatus.Response> responses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ request });
        Test.stopTest();

        GetOrderStatus.Response response = responses[0];
        System.assertEquals(true, response.found);
        System.assertEquals(2, response.orders.size(), 'Only Astrid\'s 2 orders should be returned, not Erik\'s');
    }

    @isTest
    static void testOrderLookupWithShipmentCallout() {
        Contact astrid = [SELECT Id FROM Contact WHERE LastName = 'Lindgren' LIMIT 1];
        Order order1 = [SELECT OrderNumber FROM Order WHERE CustomerAuthorizedById = :astrid.Id ORDER BY EffectiveDate DESC LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ShipmentMock());

        GetOrderStatus.Request request = new GetOrderStatus.Request();
        request.verifiedContactId = astrid.Id;
        request.orderNumber = order1.OrderNumber;

        Test.startTest();
        List<GetOrderStatus.Response> responses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ request });
        Test.stopTest();

        GetOrderStatus.Response response = responses[0];
        System.assertEquals(true, response.found);
        System.assertEquals(1, response.orders.size());

        GetOrderStatus.OrderResult result = response.orders[0];
        System.assertEquals('SHIPPED', result.status);
        System.assertEquals(Date.valueOf('2026-11-05'), result.estimatedDeliveryDate);
        System.assert(result.itemsSummary.contains('Fjord Modular Sofa'), 'Items summary should mention the product name');
        System.assert(result.itemsSummary.contains('x1'), 'Items summary should mention the quantity');
    }

    @isTest
    static void testNonexistentOrderNumberReturnsNotFound() {
        Contact astrid = [SELECT Id FROM Contact WHERE LastName = 'Lindgren' LIMIT 1];

        GetOrderStatus.Request request = new GetOrderStatus.Request();
        request.verifiedContactId = astrid.Id;
        request.orderNumber = 'NO-SUCH-ORDER';

        List<GetOrderStatus.Response> responses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ request });

        System.assertEquals(false, responses[0].found);
        System.assertEquals(0, responses[0].orders.size());
    }

    @isTest
    static void testOtherCustomersOrderNumberReturnsIdenticalNotFound() {
        Contact astrid = [SELECT Id FROM Contact WHERE LastName = 'Lindgren' LIMIT 1];
        Contact erik = [SELECT Id FROM Contact WHERE LastName = 'Johansson' LIMIT 1];
        Order erikOrder = [SELECT OrderNumber FROM Order WHERE CustomerAuthorizedById = :erik.Id LIMIT 1];

        // Astrid asking about Erik's real order number must look identical to a nonexistent order number.
        GetOrderStatus.Request crossCustomerRequest = new GetOrderStatus.Request();
        crossCustomerRequest.verifiedContactId = astrid.Id;
        crossCustomerRequest.orderNumber = erikOrder.OrderNumber;

        GetOrderStatus.Request nonexistentRequest = new GetOrderStatus.Request();
        nonexistentRequest.verifiedContactId = astrid.Id;
        nonexistentRequest.orderNumber = 'NO-SUCH-ORDER';

        List<GetOrderStatus.Response> crossCustomerResponses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ crossCustomerRequest });
        List<GetOrderStatus.Response> nonexistentResponses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ nonexistentRequest });

        System.assertEquals(false, crossCustomerResponses[0].found);
        System.assertEquals(nonexistentResponses[0].found, crossCustomerResponses[0].found);
        System.assertEquals(nonexistentResponses[0].orders.size(), crossCustomerResponses[0].orders.size());
    }

    @isTest
    static void testShipmentNotFoundLeavesStatusUnset() {
        Contact astrid = [SELECT Id FROM Contact WHERE LastName = 'Lindgren' LIMIT 1];
        Order order1 = [SELECT OrderNumber FROM Order WHERE CustomerAuthorizedById = :astrid.Id ORDER BY EffectiveDate DESC LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new NotFoundShipmentMock());

        GetOrderStatus.Request request = new GetOrderStatus.Request();
        request.verifiedContactId = astrid.Id;
        request.orderNumber = order1.OrderNumber;

        Test.startTest();
        List<GetOrderStatus.Response> responses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ request });
        Test.stopTest();

        System.assertEquals(true, responses[0].found, 'The Order itself exists even if the shipment lookup 404s');
        System.assertEquals(null, responses[0].orders[0].status);
    }

    @isTest
    static void testMissingVerifiedContactIdReturnsNotFound() {
        GetOrderStatus.Request request = new GetOrderStatus.Request();
        request.orderNumber = 'NH-1001';

        List<GetOrderStatus.Response> responses = GetOrderStatus.execute(new List<GetOrderStatus.Request>{ request });

        System.assertEquals(false, responses[0].found);
    }
}
