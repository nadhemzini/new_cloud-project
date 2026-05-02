import React from 'react';

function ItemList({ items, onDelete }) {
  if (items.length === 0) {
    return (
      <div className="empty-state">
        <span className="empty-icon">📦</span>
        <p>No items yet. Create one above!</p>
      </div>
    );
  }

  return (
    <ul className="item-list">
      {items.map((item) => (
        <li key={item.id} className="item-card">
          <div className="item-info">
            <h4 className="item-name">{item.name}</h4>
            {item.description && (
              <p className="item-description">{item.description}</p>
            )}
            <span className="item-date">
              {new Date(item.createdAt).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
              })}
            </span>
          </div>
          <button
            className="btn-delete"
            onClick={() => onDelete(item.id)}
            aria-label={`Delete ${item.name}`}
            title="Delete item"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
              <line x1="10" y1="11" x2="10" y2="17"></line>
              <line x1="14" y1="11" x2="14" y2="17"></line>
            </svg>
          </button>
        </li>
      ))}
    </ul>
  );
}

export default ItemList;
