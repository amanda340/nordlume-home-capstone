// Seed data for the Nordlume Home Advisor Agent capstone MVP.
// Creates: 1 Account, 6 Contacts, 24 Product2 (matching mock-api SKUs),
// standard PricebookEntries for each product, and 10 Order + OrderItem records.
//
// NOTE: Order.OrderNumber is an autonumber field in this org (not createable/updateable),
// so the 10 Orders below are inserted in the exact sequence of the spec's NH-1001..NH-1010
// table and the ACTUAL autonumber values the org assigns are queried back and printed at
// the end -- they are not assumed to be NH-1001..NH-1010.
//
// NOTE: this org's standard Order object does not have BillToContactId/ShipToContactId
// fields (only CustomerAuthorizedById and CompanyAuthorizedById reference Contact/User).
// CustomerAuthorizedById is used as the "customer on the order" field throughout.

// ---------- 1. Account ----------
Account account = new Account(Name = 'Nordlume Customers');
insert account;

// ---------- 2. Contacts ----------
Map<String, Contact> contactsByFullName = new Map<String, Contact>();
List<Contact> contactsToInsert = new List<Contact>();

List<String> contactNames = new List<String>{
    'Astrid Lindgren',
    'Erik Johansson',
    'Freya Nilsson',
    'Oskar Berg',
    'Linnea Karlsson',
    'Magnus Holm'
};

for (String fullName : contactNames) {
    List<String> parts = fullName.split(' ');
    String firstName = parts[0];
    String lastName = parts[1];
    String email = (firstName + '.' + lastName).toLowerCase() + '@example.com';

    Contact c = new Contact(
        FirstName = firstName,
        LastName = lastName,
        Email = email,
        AccountId = account.Id
    );
    contactsToInsert.add(c);
}

insert contactsToInsert;

for (Contact c : contactsToInsert) {
    contactsByFullName.put(c.FirstName + ' ' + c.LastName, c);
}

// ---------- 3. Products (24 SKUs from storefront/data/products.json) ----------
List<Map<String, Object>> productData = new List<Map<String, Object>>{
    new Map<String, Object>{ 'sku' => 'SOF-N001', 'name' => 'Fjord Modular Sofa', 'price' => 1299 },
    new Map<String, Object>{ 'sku' => 'SOF-N002', 'name' => 'Lumi Loveseat', 'price' => 799 },
    new Map<String, Object>{ 'sku' => 'SOF-N003', 'name' => 'Birk Sleeper Sofa', 'price' => 999 },
    new Map<String, Object>{ 'sku' => 'SOF-N004', 'name' => 'Vika Corner Sectional', 'price' => 1599 },
    new Map<String, Object>{ 'sku' => 'TBL-N010', 'name' => 'Alna Extendable Dining Table', 'price' => 549 },
    new Map<String, Object>{ 'sku' => 'TBL-N011', 'name' => 'Myro Nesting Side Tables', 'price' => 179 },
    new Map<String, Object>{ 'sku' => 'TBL-N012', 'name' => 'Kaja Fold-Down Desk', 'price' => 289 },
    new Map<String, Object>{ 'sku' => 'TBL-N013', 'name' => 'Solvi Coffee Table', 'price' => 229 },
    new Map<String, Object>{ 'sku' => 'CHR-N020', 'name' => 'Pilt Accent Chair', 'price' => 349 },
    new Map<String, Object>{ 'sku' => 'CHR-N021', 'name' => 'Rono Dining Chair', 'price' => 129 },
    new Map<String, Object>{ 'sku' => 'CHR-N022', 'name' => 'Sten Task Chair', 'price' => 259 },
    new Map<String, Object>{ 'sku' => 'CHR-N023', 'name' => 'Hagen Folding Chair', 'price' => 89 },
    new Map<String, Object>{ 'sku' => 'LGT-N030', 'name' => 'Skye Floor Lamp', 'price' => 159 },
    new Map<String, Object>{ 'sku' => 'LGT-N031', 'name' => 'Tove Pendant Light', 'price' => 119 },
    new Map<String, Object>{ 'sku' => 'LGT-N032', 'name' => 'Ren Desk Lamp', 'price' => 69 },
    new Map<String, Object>{ 'sku' => 'LGT-N033', 'name' => 'Isla Table Lamp', 'price' => 89 },
    new Map<String, Object>{ 'sku' => 'STG-N040', 'name' => 'Ovra Storage Bench', 'price' => 219 },
    new Map<String, Object>{ 'sku' => 'STG-N041', 'name' => 'Kalla Modular Shelving', 'price' => 329 },
    new Map<String, Object>{ 'sku' => 'STG-N042', 'name' => 'Bru Under-Bed Drawers', 'price' => 99 },
    new Map<String, Object>{ 'sku' => 'STG-N043', 'name' => 'Nord Shoe Cabinet', 'price' => 179 },
    new Map<String, Object>{ 'sku' => 'STG-N044', 'name' => 'Eir Wardrobe', 'price' => 399 },
    new Map<String, Object>{ 'sku' => 'SOF-N005', 'name' => 'Hale Chaise Module', 'price' => 499 },
    new Map<String, Object>{ 'sku' => 'TBL-N014', 'name' => 'Elva Console Table', 'price' => 199 },
    new Map<String, Object>{ 'sku' => 'CHR-N024', 'name' => 'Vindel Lounge Chair', 'price' => 429 }
};

Map<String, Product2> productsBySku = new Map<String, Product2>();
List<Product2> productsToInsert = new List<Product2>();

for (Map<String, Object> row : productData) {
    Product2 p = new Product2(
        Name = (String) row.get('name'),
        SKU__c = (String) row.get('sku'),
        IsActive = true
    );
    productsToInsert.add(p);
}

insert productsToInsert;

for (Integer i = 0; i < productsToInsert.size(); i++) {
    productsBySku.put((String) productData[i].get('sku'), productsToInsert[i]);
}

// ---------- 4. Standard Pricebook entries ----------
Pricebook2 standardPricebook = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!standardPricebook.IsActive) {
    standardPricebook.IsActive = true;
    update standardPricebook;
}
Id standardPricebookId = standardPricebook.Id;

List<PricebookEntry> entriesToInsert = new List<PricebookEntry>();
for (Map<String, Object> row : productData) {
    Product2 p = productsBySku.get((String) row.get('sku'));
    entriesToInsert.add(new PricebookEntry(
        Pricebook2Id = standardPricebookId,
        Product2Id = p.Id,
        UnitPrice = (Integer) row.get('price'),
        IsActive = true
    ));
}

insert entriesToInsert;

Map<Id, Id> pricebookEntryByProductId = new Map<Id, Id>();
for (PricebookEntry pbe : entriesToInsert) {
    pricebookEntryByProductId.put(pbe.Product2Id, pbe.Id);
}

// ---------- 5. Orders + OrderItems ----------
// Each row: contact full name, list of "SKU x qty" line items.
List<Map<String, Object>> orderSpecs = new List<Map<String, Object>>{
    new Map<String, Object>{ 'contact' => 'Astrid Lindgren', 'items' => new List<Object>{ 'SOF-N001:1' } },
    new Map<String, Object>{ 'contact' => 'Astrid Lindgren', 'items' => new List<Object>{ 'TBL-N013:1' } },
    new Map<String, Object>{ 'contact' => 'Erik Johansson', 'items' => new List<Object>{ 'CHR-N021:4' } },
    new Map<String, Object>{ 'contact' => 'Freya Nilsson', 'items' => new List<Object>{ 'LGT-N030:2' } },
    new Map<String, Object>{ 'contact' => 'Oskar Berg', 'items' => new List<Object>{ 'STG-N041:2' } },
    new Map<String, Object>{ 'contact' => 'Oskar Berg', 'items' => new List<Object>{ 'TBL-N010:1' } },
    new Map<String, Object>{ 'contact' => 'Linnea Karlsson', 'items' => new List<Object>{ 'SOF-N003:1' } },
    new Map<String, Object>{ 'contact' => 'Linnea Karlsson', 'items' => new List<Object>{ 'CHR-N024:1', 'LGT-N033:1' } },
    new Map<String, Object>{ 'contact' => 'Magnus Holm', 'items' => new List<Object>{ 'STG-N043:1' } },
    new Map<String, Object>{ 'contact' => 'Magnus Holm', 'items' => new List<Object>{ 'SOF-N002:1' } }
};

List<Order> ordersToInsert = new List<Order>();
for (Map<String, Object> spec : orderSpecs) {
    Contact c = contactsByFullName.get((String) spec.get('contact'));
    Order o = new Order(
        AccountId = account.Id,
        CustomerAuthorizedById = c.Id,
        Pricebook2Id = standardPricebookId,
        EffectiveDate = Date.today(),
        Status = 'Draft'
    );
    ordersToInsert.add(o);
}

insert ordersToInsert;

List<OrderItem> orderItemsToInsert = new List<OrderItem>();
for (Integer i = 0; i < orderSpecs.size(); i++) {
    Order o = ordersToInsert[i];
    List<Object> items = (List<Object>) orderSpecs[i].get('items');

    for (Object itemObj : items) {
        List<String> parts = ((String) itemObj).split(':');
        String sku = parts[0];
        Integer qty = Integer.valueOf(parts[1]);

        Product2 p = productsBySku.get(sku);
        Id pbeId = pricebookEntryByProductId.get(p.Id);

        orderItemsToInsert.add(new OrderItem(
            OrderId = o.Id,
            Product2Id = p.Id,
            PricebookEntryId = pbeId,
            Quantity = qty,
            UnitPrice = entriesToInsert[0].UnitPrice // placeholder, corrected below
        ));
    }
}

// Correct UnitPrice per line using the product's actual catalog price (built above).
Map<Id, Decimal> priceByProductId = new Map<Id, Decimal>();
for (Integer i = 0; i < productsToInsert.size(); i++) {
    priceByProductId.put(productsToInsert[i].Id, (Integer) productData[i].get('price'));
}
for (OrderItem oi : orderItemsToInsert) {
    oi.UnitPrice = priceByProductId.get(oi.Product2Id);
}

insert orderItemsToInsert;

// ---------- 6. Activate orders ----------
for (Order o : ordersToInsert) {
    o.Status = 'Activated';
}
update ordersToInsert;

// ---------- 7. Report actual OrderNumbers ----------
List<Order> finalOrders = [
    SELECT Id, OrderNumber, Status, CustomerAuthorizedBy.Name
    FROM Order
    WHERE Id IN :ordersToInsert
    ORDER BY CreatedDate ASC
];

System.debug('=== SEED COMPLETE ===');
for (Order o : finalOrders) {
    System.debug('OrderNumber=' + o.OrderNumber + ' Status=' + o.Status + ' Customer=' + o.CustomerAuthorizedBy.Name);
}
System.debug('Product2 count: ' + [SELECT COUNT() FROM Product2]);
System.debug('Contact count: ' + [SELECT COUNT() FROM Contact]);
System.debug('Account count: ' + [SELECT COUNT() FROM Account]);
System.debug('Order count: ' + [SELECT COUNT() FROM Order]);
System.debug('OrderItem count: ' + [SELECT COUNT() FROM OrderItem]);
