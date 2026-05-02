const API_URL = import.meta.env.VITE_API_URL || '';

export async function fetchItems() {
  const res = await fetch(`${API_URL}/api/items`);
  if (!res.ok) throw new Error('Failed to fetch items');
  return res.json();
}

export async function createItem(item) {
  const res = await fetch(`${API_URL}/api/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(item),
  });
  if (!res.ok) throw new Error('Failed to create item');
  return res.json();
}

export async function deleteItem(id) {
  const res = await fetch(`${API_URL}/api/items/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok) throw new Error('Failed to delete item');
}

export async function checkHealth() {
  try {
    const res = await fetch(`${API_URL}/actuator/health`);
    if (!res.ok) return { status: 'DOWN' };
    return res.json();
  } catch {
    return { status: 'DOWN' };
  }
}
