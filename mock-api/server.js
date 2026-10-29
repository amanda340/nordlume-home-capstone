const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const PORT = process.env.PORT || 3001;
const API_KEY = process.env.API_KEY || null;

const products = JSON.parse(
  fs.readFileSync(path.join(__dirname, "data", "products.json"), "utf8"),
).map(({ image, ...rest }) => rest);

const shipments = JSON.parse(
  fs.readFileSync(path.join(__dirname, "data", "shipments.json"), "utf8"),
);

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(payload),
  });
  res.end(payload);
}

function isAuthorized(req) {
  if (!API_KEY) return true;
  return req.headers["x-api-key"] === API_KEY;
}

function searchProducts({ category, q }) {
  return products.filter((product) => {
    const matchesCategory =
      !category || product.category.toLowerCase() === category.toLowerCase();
    const matchesQuery =
      !q ||
      product.name.toLowerCase().includes(q.toLowerCase()) ||
      product.description.toLowerCase().includes(q.toLowerCase());
    return matchesCategory && matchesQuery;
  });
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === "/health") {
    sendJson(res, 200, { status: "ok" });
    return;
  }

  if (req.method !== "GET") {
    sendJson(res, 405, { error: "METHOD_NOT_ALLOWED" });
    return;
  }

  if (!isAuthorized(req)) {
    sendJson(res, 401, { error: "UNAUTHORIZED" });
    return;
  }

  if (url.pathname === "/products") {
    const category = url.searchParams.get("category");
    const q = url.searchParams.get("q");
    sendJson(res, 200, searchProducts({ category, q }));
    return;
  }

  const productMatch = url.pathname.match(/^\/products\/([^/]+)$/);
  if (productMatch) {
    const sku = decodeURIComponent(productMatch[1]);
    const product = products.find(
      (p) => p.sku.toLowerCase() === sku.toLowerCase(),
    );
    if (!product) {
      sendJson(res, 404, { error: "NOT_FOUND" });
      return;
    }
    sendJson(res, 200, product);
    return;
  }

  const shipmentMatch = url.pathname.match(/^\/orders\/([^/]+)\/shipments$/);
  if (shipmentMatch) {
    const orderNumber = decodeURIComponent(shipmentMatch[1]);
    const shipment = shipments.find(
      (s) => s.orderNumber.toLowerCase() === orderNumber.toLowerCase(),
    );
    if (!shipment) {
      sendJson(res, 404, { error: "NOT_FOUND" });
      return;
    }
    sendJson(res, 200, shipment);
    return;
  }

  sendJson(res, 404, { error: "NOT_FOUND" });
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`Nordlume mock API listening on port ${PORT}`);
  });
}

module.exports = { server, products, shipments };
