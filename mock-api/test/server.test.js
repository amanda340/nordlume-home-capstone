const test = require("node:test");
const assert = require("node:assert/strict");
const { server } = require("../server.js");

function request(path, headers = {}) {
  return new Promise((resolve, reject) => {
    const address = server.address();
    const options = {
      host: "127.0.0.1",
      port: address.port,
      path,
      method: "GET",
      headers,
    };
    const req = require("node:http").request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () =>
        resolve({ status: res.statusCode, body: JSON.parse(body) }),
      );
    });
    req.on("error", reject);
    req.end();
  });
}

test.before(() => {
  server.listen(0);
});

test.after(() => {
  server.close();
});

test("GET /products returns the full catalog", async () => {
  const { status, body } = await request("/products");
  assert.equal(status, 200);
  assert.ok(Array.isArray(body));
  assert.ok(body.length > 0);
  assert.equal(body[0].image, undefined);
});

test("GET /products?category=Sofas filters by category", async () => {
  const { status, body } = await request("/products?category=Sofas");
  assert.equal(status, 200);
  assert.ok(body.every((p) => p.category === "Sofas"));
});

test("GET /products/:sku returns a single product", async () => {
  const { status, body } = await request("/products/SOF-N001");
  assert.equal(status, 200);
  assert.equal(body.sku, "SOF-N001");
});

test("GET /products/:sku returns 404 for unknown sku", async () => {
  const { status, body } = await request("/products/DOES-NOT-EXIST");
  assert.equal(status, 404);
  assert.equal(body.error, "NOT_FOUND");
});

test("GET /orders/:orderNumber/shipments returns shipment status", async () => {
  const { status, body } = await request("/orders/NH-1001/shipments");
  assert.equal(status, 200);
  assert.equal(body.status, "DELIVERED");
});

test("GET /orders/:orderNumber/shipments returns 404 for unknown order", async () => {
  const { status, body } = await request("/orders/NH-9999/shipments");
  assert.equal(status, 404);
  assert.equal(body.error, "NOT_FOUND");
});
