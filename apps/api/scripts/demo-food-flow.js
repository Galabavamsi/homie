const baseUrl = process.env.HOMIE_API_URL || 'http://localhost:4000/api';
const query = process.argv[2] || 'pizza';
const confirmOrder = process.argv.includes('--confirm');

const response = await fetch(`${baseUrl}/demo/food-agent`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query, confirmOrder })
});

const payload = await response.json();

if (!response.ok) {
  console.error(JSON.stringify(payload, null, 2));
  process.exit(1);
}

console.log(`Homie local Food MCP demo: ${payload.status}`);
if (payload.restaurant) console.log(`Restaurant: ${payload.restaurant.name}`);
if (payload.selectedItem) console.log(`Item: ${payload.selectedItem.name}`);
if (payload.cart) console.log(`Cart total: ₹${payload.cart.total}`);
if (payload.confirmation) console.log(payload.confirmation.message);
if (payload.order) console.log(payload.order.message || `Order id: ${payload.order.orderId}`);
console.log('\nTool transcript:');
for (const entry of payload.transcript || []) {
  console.log(`- ${entry.tool}`);
}
