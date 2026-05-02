import React, { useState, useEffect } from 'react';
import ItemList from './components/ItemList';
import ItemForm from './components/ItemForm';
import { fetchItems, createItem, deleteItem, checkHealth } from './services/api';

function App() {
  const [items, setItems] = useState([]);
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadItems = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchItems();
      setItems(data);
    } catch (err) {
      setError('Failed to load items. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  const loadHealth = async () => {
    const result = await checkHealth();
    setHealth(result.status);
  };

  useEffect(() => {
    loadItems();
    loadHealth();
    const interval = setInterval(loadHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleCreate = async (item) => {
    try {
      setError(null);
      await createItem(item);
      await loadItems();
    } catch (err) {
      setError('Failed to create item.');
    }
  };

  const handleDelete = async (id) => {
    try {
      setError(null);
      await deleteItem(id);
      await loadItems();
    } catch (err) {
      setError('Failed to delete item.');
    }
  };

  return (
    <div className="app">
      {/* Animated background orbs */}
      <div className="bg-orb bg-orb-1"></div>
      <div className="bg-orb bg-orb-2"></div>
      <div className="bg-orb bg-orb-3"></div>

      <header className="app-header">
        <div className="header-content">
          <div className="logo">
            <span className="logo-icon">☁️</span>
            <h1>Cloud Stack</h1>
          </div>
          <div className={`health-badge ${health === 'UP' ? 'health-up' : 'health-down'}`}>
            <span className="health-dot"></span>
            <span>API {health === 'UP' ? 'Connected' : 'Offline'}</span>
          </div>
        </div>
      </header>

      <main className="app-main">
        <section className="hero-section">
          <h2 className="hero-title">Items Manager</h2>
          <p className="hero-subtitle">
            Full-stack CRUD application — React · Spring Boot · PostgreSQL · AWS
          </p>
        </section>

        {error && (
          <div className="error-banner">
            <span className="error-icon">⚠️</span>
            <span>{error}</span>
            <button className="error-dismiss" onClick={() => setError(null)}>✕</button>
          </div>
        )}

        <div className="content-grid">
          <div className="form-panel">
            <div className="panel glass-panel">
              <h3 className="panel-title">Create New Item</h3>
              <ItemForm onSubmit={handleCreate} />
            </div>
          </div>

          <div className="list-panel">
            <div className="panel glass-panel">
              <div className="panel-header">
                <h3 className="panel-title">All Items</h3>
                <span className="item-count">{items.length}</span>
              </div>
              {loading ? (
                <div className="loading-spinner">
                  <div className="spinner"></div>
                  <p>Loading items…</p>
                </div>
              ) : (
                <ItemList items={items} onDelete={handleDelete} />
              )}
            </div>
          </div>
        </div>
      </main>

      <footer className="app-footer">
        <p>Cloud Stack Demo — Deployed with Terraform on AWS ECS Fargate</p>
      </footer>
    </div>
  );
}

export default App;
