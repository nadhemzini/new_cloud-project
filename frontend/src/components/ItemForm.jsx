import React, { useState } from 'react';

function ItemForm({ onSubmit }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name.trim()) return;

    setSubmitting(true);
    await onSubmit({ name: name.trim(), description: description.trim() });
    setName('');
    setDescription('');
    setSubmitting(false);
  };

  return (
    <form className="item-form" onSubmit={handleSubmit}>
      <div className="form-group">
        <label htmlFor="item-name" className="form-label">Name</label>
        <input
          id="item-name"
          type="text"
          className="form-input"
          placeholder="Enter item name…"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          maxLength={255}
          disabled={submitting}
        />
      </div>
      <div className="form-group">
        <label htmlFor="item-description" className="form-label">Description</label>
        <textarea
          id="item-description"
          className="form-input form-textarea"
          placeholder="Optional description…"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          maxLength={1000}
          rows={3}
          disabled={submitting}
        />
      </div>
      <button
        type="submit"
        className="btn-submit"
        disabled={!name.trim() || submitting}
      >
        {submitting ? (
          <>
            <span className="btn-spinner"></span>
            Creating…
          </>
        ) : (
          <>
            <span>+</span>
            Add Item
          </>
        )}
      </button>
    </form>
  );
}

export default ItemForm;
