import React, { useState, useEffect } from "react";

const API_BASE = "http://localhost:3001/api";

// Estilos CSS inline
const styles = `
  .admin-container {
    min-height: 100vh;
    background: #f9fafb;
  }

  .admin-header {
    background: linear-gradient(to right, #ec4899, #a855f7);
    color: white;
    padding: 2rem 0;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .admin-header h1 {
    font-size: 2rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
  }

  .admin-header p {
    color: #fce7f3;
    font-size: 1rem;
  }

  .admin-nav {
    background: white;
    border-bottom: 2px solid #e5e7eb;
    position: sticky;
    top: 0;
    z-index: 30;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .admin-nav .container {
    display: flex;
    gap: 0.5rem;
    padding: 0;
  }

  .admin-nav-button {
    background: none;
    border: none;
    padding: 1rem 1.5rem;
    font-size: 1rem;
    font-weight: 500;
    color: #6b7280;
    cursor: pointer;
    border-bottom: 2px solid transparent;
    transition: all 0.2s;
  }

  .admin-nav-button:hover {
    color: #ec4899;
    background: #fce7f3;
  }

  .admin-nav-button.active {
    color: #ec4899;
    border-bottom-color: #ec4899;
    font-weight: 600;
  }

  .admin-main {
    padding: 2rem 0;
  }

  .admin-notification {
    position: fixed;
    top: 1rem;
    right: 1rem;
    z-index: 100;
    padding: 1rem 1.5rem;
    border-radius: 0.5rem;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    color: white;
    font-weight: 500;
    animation: slideInRight 0.3s ease-out;
  }

  .admin-notification.success {
    background: #10b981;
  }

  .admin-notification.error {
    background: #ef4444;
  }

  @keyframes slideInRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  .dashboard h2 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 2rem;
  }

  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .stat-card {
    background: white;
    border-radius: 0.75rem;
    padding: 1.5rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    gap: 1rem;
    color: white;
  }

  .stat-blue {
    background: linear-gradient(135deg, #3b82f6, #2563eb);
  }

  .stat-green {
    background: linear-gradient(135deg, #10b981, #059669);
  }

  .stat-pink {
    background: linear-gradient(135deg, #ec4899, #db2777);
  }

  .stat-yellow {
    background: linear-gradient(135deg, #f59e0b, #d97706);
  }

  .stat-icon {
    font-size: 3rem;
  }

  .stat-content {
    flex: 1;
  }

  .stat-label {
    font-size: 0.875rem;
    opacity: 0.9;
    margin-bottom: 0.5rem;
  }

  .stat-value {
    font-size: 2rem;
    font-weight: 700;
  }

  .top-cupcake-card {
    background: white;
    border-radius: 0.75rem;
    padding: 1.5rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .top-cupcake-card h3 {
    font-size: 1.25rem;
    font-weight: 600;
    color: #1f2937;
    margin-bottom: 1rem;
  }

  .top-cupcake-content {
    display: flex;
    align-items: center;
    gap: 1.5rem;
  }

  .top-cupcake-icon {
    font-size: 4rem;
  }

  .top-cupcake-name {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.25rem;
  }

  .top-cupcake-sales {
    color: #6b7280;
    font-size: 1rem;
  }

  .cupcakes-tab h2,
  .orders-tab h2 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 2rem;
  }

  .tab-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }

  .tab-header h2 {
    margin: 0;
  }

  .btn-primary {
    background: linear-gradient(to right, #ec4899, #a855f7);
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 0.5rem;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .btn-primary:hover {
    background: linear-gradient(to right, #db2777, #9333ea);
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  }

  .admin-cupcakes-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1.5rem;
  }

  .admin-cupcake-card {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    transition: all 0.3s;
  }

  .admin-cupcake-card:hover {
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    transform: translateY(-2px);
  }

  .admin-cupcake-image {
    position: relative;
    height: 12rem;
    background: linear-gradient(135deg, #fce7f3, #e9d5ff);
  }

  .admin-cupcake-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .admin-cupcake-fallback {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: none;
    align-items: center;
    justify-content: center;
    font-size: 4rem;
    background: linear-gradient(135deg, #fce7f3, #e9d5ff);
  }

  .admin-cupcake-content {
    padding: 1rem;
  }

  .admin-cupcake-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
  }

  .admin-cupcake-header h3 {
    font-size: 1.125rem;
    font-weight: 700;
    color: #1f2937;
  }

  .status-badge {
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
  }

  .status-active {
    background: #d1fae5;
    color: #065f46;
  }

  .status-inactive {
    background: #fee2e2;
    color: #991b1b;
  }

  .status-pending {
    background: #fef3c7;
    color: #92400e;
  }

  .status-processing {
    background: #dbeafe;
    color: #1e40af;
  }

  .status-completed {
    background: #d1fae5;
    color: #065f46;
  }

  .status-cancelled {
    background: #fee2e2;
    color: #991b1b;
  }

  .admin-cupcake-description {
    color: #6b7280;
    font-size: 0.875rem;
    margin-bottom: 0.75rem;
    line-height: 1.4;
  }

  .admin-cupcake-price {
    font-size: 1.5rem;
    font-weight: 700;
    color: #ec4899;
    margin-bottom: 1rem;
  }

  .admin-cupcake-actions {
    display: flex;
    gap: 0.5rem;
  }

  .btn-edit,
  .btn-delete {
    flex: 1;
    border: none;
    padding: 0.5rem;
    border-radius: 0.5rem;
    font-size: 0.875rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-edit {
    background: #3b82f6;
    color: white;
  }

  .btn-edit:hover {
    background: #2563eb;
  }

  .btn-delete {
    background: #ef4444;
    color: white;
  }

  .btn-delete:hover {
    background: #dc2626;
  }

  .orders-table-container {
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  .orders-table {
    width: 100%;
    border-collapse: collapse;
  }

  .orders-table thead {
    background: #f9fafb;
    border-bottom: 2px solid #e5e7eb;
  }

  .orders-table th {
    padding: 1rem;
    text-align: left;
    font-size: 0.75rem;
    font-weight: 600;
    color: #6b7280;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .orders-table td {
    padding: 1rem;
    border-bottom: 1px solid #e5e7eb;
  }

  .orders-table tbody tr:hover {
    background: #f9fafb;
  }

  .order-id {
    font-weight: 600;
    color: #1f2937;
  }

  .customer-info {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .customer-name {
    font-weight: 500;
    color: #1f2937;
  }

  .customer-email {
    font-size: 0.875rem;
    color: #6b7280;
  }

  .order-items {
    color: #6b7280;
    font-size: 0.875rem;
    max-width: 300px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .order-total {
    font-weight: 700;
    color: #ec4899;
    font-size: 1rem;
  }

  .status-select {
    padding: 0.5rem;
    border: 1px solid #d1d5db;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
  }

  .status-select:focus {
    outline: none;
    border-color: #ec4899;
    box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
  }

  .cupcake-modal {
    max-width: 600px;
  }

  .cupcake-form {
    padding: 1.5rem;
  }

  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }

  .cupcake-form .form-group {
    margin-bottom: 1rem;
  }

  .cupcake-form .form-group label {
    display: block;
    font-weight: 500;
    color: #374151;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
  }

  .cupcake-form input,
  .cupcake-form textarea,
  .cupcake-form select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 0.5rem;
    font-size: 0.875rem;
    transition: all 0.2s;
  }

  .cupcake-form input:focus,
  .cupcake-form textarea:focus,
  .cupcake-form select:focus {
    outline: none;
    border-color: #ec4899;
    box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
  }

  .cupcake-form textarea {
    resize: vertical;
    font-family: inherit;
  }

  .checkbox-group {
    display: flex;
    align-items: center;
  }

  .checkbox-group label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    font-weight: 400 !important;
  }

  .checkbox-group input[type="checkbox"] {
    width: auto;
    cursor: pointer;
  }

  .btn-submit {
    width: 100%;
    background: linear-gradient(to right, #ec4899, #a855f7);
    color: white;
    border: none;
    padding: 0.75rem;
    border-radius: 0.5rem;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .btn-submit:hover:not(:disabled) {
    background: linear-gradient(to right, #db2777, #9333ea);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(236, 72, 153, 0.4);
  }

  .btn-submit:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  @media (max-width: 768px) {
    .admin-header h1 {
      font-size: 1.5rem;
    }

    .admin-nav .container {
      flex-direction: column;
    }

    .admin-nav-button {
      text-align: left;
      border-bottom: 1px solid #e5e7eb;
    }

    .admin-nav-button.active {
      border-left: 3px solid #ec4899;
      border-bottom: 1px solid #e5e7eb;
    }

    .stats-grid {
      grid-template-columns: 1fr;
    }

    .tab-header {
      flex-direction: column;
      align-items: stretch;
      gap: 1rem;
    }

    .admin-cupcakes-grid {
      grid-template-columns: 1fr;
    }

    .form-row {
      grid-template-columns: 1fr;
    }

    .orders-table-container {
      overflow-x: auto;
    }

    .orders-table {
      min-width: 800px;
    }
  }
`;

const AdminPanel = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [stats, setStats] = useState(null);
  const [cupcakes, setCupcakes] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showCupcakeModal, setShowCupcakeModal] = useState(false);
  const [editingCupcake, setEditingCupcake] = useState(null);
  const [notification, setNotification] = useState(null);

  useEffect(() => {
    if (activeTab === "dashboard") fetchStats();
    if (activeTab === "cupcakes") fetchCupcakes();
    if (activeTab === "orders") fetchOrders();
  }, [activeTab]);

  const showNotification = (message, type = "success") => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const fetchStats = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/admin/stats`);
      const data = await res.json();
      setStats(data);
    } catch (error) {
      console.error("Erro ao carregar estatísticas:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchCupcakes = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/admin/cupcakes`);
      const data = await res.json();
      setCupcakes(data);
    } catch (error) {
      console.error("Erro ao carregar cupcakes:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/orders`);
      const data = await res.json();
      setOrders(data);
    } catch (error) {
      console.error("Erro ao carregar pedidos:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCupcake = async (id) => {
    if (!window.confirm("Tem certeza que deseja deletar este cupcake?")) return;

    try {
      const res = await fetch(`${API_BASE}/admin/cupcakes/${id}`, {
        method: "DELETE",
      });
      const result = await res.json();

      if (result.success) {
        showNotification("Cupcake deletado com sucesso!");
        fetchCupcakes();
      }
    } catch (error) {
      showNotification("Erro ao deletar cupcake", "error");
    }
  };

  const handleUpdateOrderStatus = async (orderId, newStatus) => {
    try {
      const res = await fetch(`${API_BASE}/admin/orders/${orderId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      const result = await res.json();

      if (result.success) {
        showNotification("Status atualizado com sucesso!");
        fetchOrders();
      }
    } catch (error) {
      showNotification("Erro ao atualizar status", "error");
    }
  };

  return (
    <>
      <style>{styles}</style>
      <div className="admin-container">
        {notification && (
          <div className={`admin-notification ${notification.type}`}>
            {notification.message}
          </div>
        )}

        <header className="admin-header">
          <div className="container">
            <h1>🧁 Painel Administrativo</h1>
            <p>Gerencie cupcakes, pedidos e visualize estatísticas</p>
          </div>
        </header>

        <nav className="admin-nav">
          <div className="container">
            <button
              onClick={() => setActiveTab("dashboard")}
              className={`admin-nav-button ${
                activeTab === "dashboard" ? "active" : ""
              }`}
            >
              📊 Dashboard
            </button>
            <button
              onClick={() => setActiveTab("cupcakes")}
              className={`admin-nav-button ${
                activeTab === "cupcakes" ? "active" : ""
              }`}
            >
              🧁 Cupcakes
            </button>
            <button
              onClick={() => setActiveTab("orders")}
              className={`admin-nav-button ${
                activeTab === "orders" ? "active" : ""
              }`}
            >
              📦 Pedidos
            </button>
          </div>
        </nav>

        <main className="admin-main container">
          {loading && (
            <div className="loading">
              <div className="spinner"></div>
            </div>
          )}

          {!loading && activeTab === "dashboard" && <Dashboard stats={stats} />}

          {!loading && activeTab === "cupcakes" && (
            <CupcakesTab
              cupcakes={cupcakes}
              onAdd={() => {
                setEditingCupcake(null);
                setShowCupcakeModal(true);
              }}
              onEdit={(cupcake) => {
                setEditingCupcake(cupcake);
                setShowCupcakeModal(true);
              }}
              onDelete={handleDeleteCupcake}
            />
          )}

          {!loading && activeTab === "orders" && (
            <OrdersTab
              orders={orders}
              onUpdateStatus={handleUpdateOrderStatus}
            />
          )}
        </main>

        {showCupcakeModal && (
          <CupcakeModal
            cupcake={editingCupcake}
            onClose={() => {
              setShowCupcakeModal(false);
              setEditingCupcake(null);
            }}
            onSuccess={() => {
              setShowCupcakeModal(false);
              setEditingCupcake(null);
              fetchCupcakes();
              showNotification(
                editingCupcake ? "Cupcake atualizado!" : "Cupcake criado!"
              );
            }}
          />
        )}
      </div>
    </>
  );
};

const Dashboard = ({ stats }) => {
  if (!stats) return null;

  return (
    <div className="dashboard">
      <h2>Estatísticas Gerais</h2>

      <div className="stats-grid">
        <div className="stat-card stat-blue">
          <div className="stat-icon">📦</div>
          <div className="stat-content">
            <div className="stat-label">Total de Pedidos</div>
            <div className="stat-value">{stats.totalOrders}</div>
          </div>
        </div>

        <div className="stat-card stat-green">
          <div className="stat-icon">💰</div>
          <div className="stat-content">
            <div className="stat-label">Receita Total</div>
            <div className="stat-value">
              R$ {parseFloat(stats.totalRevenue).toFixed(2)}
            </div>
          </div>
        </div>

        <div className="stat-card stat-pink">
          <div className="stat-icon">🧁</div>
          <div className="stat-content">
            <div className="stat-label">Cupcakes Disponíveis</div>
            <div className="stat-value">{stats.totalCupcakes}</div>
          </div>
        </div>

        <div className="stat-card stat-yellow">
          <div className="stat-icon">⏳</div>
          <div className="stat-content">
            <div className="stat-label">Pedidos Pendentes</div>
            <div className="stat-value">{stats.pendingOrders}</div>
          </div>
        </div>
      </div>

      <div className="top-cupcake-card">
        <h3>🏆 Cupcake Mais Vendido</h3>
        <div className="top-cupcake-content">
          <div className="top-cupcake-icon">🧁</div>
          <div>
            <div className="top-cupcake-name">{stats.topCupcake.name}</div>
            <div className="top-cupcake-sales">
              {stats.topCupcake.total_sold} unidades vendidas
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const CupcakesTab = ({ cupcakes, onAdd, onEdit, onDelete }) => {
  return (
    <div className="cupcakes-tab">
      <div className="tab-header">
        <h2>Gerenciar Cupcakes</h2>
        <button onClick={onAdd} className="btn-primary">
          ➕ Novo Cupcake
        </button>
      </div>

      <div className="admin-cupcakes-grid">
        {cupcakes.map((cupcake) => (
          <div key={cupcake.id} className="admin-cupcake-card">
            <div className="admin-cupcake-image">
              {cupcake.image_url ? (
                <img
                  src={cupcake.image_url}
                  alt={cupcake.name}
                  onError={(e) => {
                    e.target.style.display = "none";
                    e.target.nextSibling.style.display = "flex";
                  }}
                />
              ) : null}
              <div className="admin-cupcake-fallback">🧁</div>
            </div>

            <div className="admin-cupcake-content">
              <div className="admin-cupcake-header">
                <h3>{cupcake.name}</h3>
                <span
                  className={`status-badge ${
                    cupcake.available ? "status-active" : "status-inactive"
                  }`}
                >
                  {cupcake.available ? "Ativo" : "Inativo"}
                </span>
              </div>

              <p className="admin-cupcake-description">{cupcake.description}</p>
              <div className="admin-cupcake-price">
                R$ {parseFloat(cupcake.price).toFixed(2)}
              </div>

              <div className="admin-cupcake-actions">
                <button onClick={() => onEdit(cupcake)} className="btn-edit">
                  ✏️ Editar
                </button>
                <button
                  onClick={() => onDelete(cupcake.id)}
                  className="btn-delete"
                >
                  🗑️ Deletar
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

const OrdersTab = ({ orders, onUpdateStatus }) => {
  const getStatusInfo = (status) => {
    const statuses = {
      pending: { class: "status-pending", label: "⏳ Pendente" },
      processing: { class: "status-processing", label: "🔄 Processando" },
      completed: { class: "status-completed", label: "✅ Concluído" },
      cancelled: { class: "status-cancelled", label: "❌ Cancelado" },
    };
    return statuses[status] || statuses.pending;
  };

  return (
    <div className="orders-tab">
      <h2>Gerenciar Pedidos</h2>

      <div className="orders-table-container">
        <table className="orders-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Cliente</th>
              <th>Itens</th>
              <th>Total</th>
              <th>Status</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => {
              const statusInfo = getStatusInfo(order.status);
              return (
                <tr key={order.id}>
                  <td className="order-id">#{order.id}</td>
                  <td>
                    <div className="customer-info">
                      <div className="customer-name">{order.customer_name}</div>
                      <div className="customer-email">
                        {order.customer_email}
                      </div>
                    </div>
                  </td>
                  <td className="order-items">{order.items || "Sem itens"}</td>
                  <td className="order-total">
                    R$ {parseFloat(order.total_amount).toFixed(2)}
                  </td>
                  <td>
                    <span className={`status-badge ${statusInfo.class}`}>
                      {statusInfo.label}
                    </span>
                  </td>
                  <td>
                    <select
                      value={order.status}
                      onChange={(e) => onUpdateStatus(order.id, e.target.value)}
                      className="status-select"
                    >
                      <option value="pending">Pendente</option>
                      <option value="processing">Processando</option>
                      <option value="completed">Concluído</option>
                      <option value="cancelled">Cancelado</option>
                    </select>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const CupcakeModal = ({ cupcake, onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    name: cupcake?.name || "",
    description: cupcake?.description || "",
    price: cupcake?.price || "",
    image_url: cupcake?.image_url || "",
    category: cupcake?.category || "chocolate",
    available: cupcake?.available !== undefined ? cupcake.available : 1,
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const url = cupcake
        ? `${API_BASE}/admin/cupcakes/${cupcake.id}`
        : `${API_BASE}/admin/cupcakes`;

      const res = await fetch(url, {
        method: cupcake ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const result = await res.json();
      if (result.success) {
        onSuccess();
      }
    } catch (error) {
      console.error("Erro ao salvar cupcake:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="modal-overlay" onClick={onClose}></div>
      <div className="modal cupcake-modal">
        <div className="modal-header">
          <h2>{cupcake ? "✏️ Editar Cupcake" : "➕ Novo Cupcake"}</h2>
          <button onClick={onClose} className="close-button">
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit} className="cupcake-form">
          <div className="form-group">
            <label>Nome *</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
              placeholder="Ex: Cupcake de Chocolate"
            />
          </div>

          <div className="form-group">
            <label>Descrição</label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              placeholder="Descrição do cupcake"
              rows="3"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Preço (R$) *</label>
              <input
                type="number"
                step="0.01"
                required
                value={formData.price}
                onChange={(e) =>
                  setFormData({ ...formData, price: e.target.value })
                }
                placeholder="8.50"
              />
            </div>

            <div className="form-group">
              <label>Categoria</label>
              <select
                value={formData.category}
                onChange={(e) =>
                  setFormData({ ...formData, category: e.target.value })
                }
              >
                <option value="chocolate">Chocolate</option>
                <option value="baunilha">Baunilha</option>
                <option value="frutas">Frutas</option>
                <option value="especial">Especial</option>
                <option value="outros">Outros</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>URL da Imagem</label>
            <input
              type="url"
              value={formData.image_url}
              onChange={(e) =>
                setFormData({ ...formData, image_url: e.target.value })
              }
              placeholder="https://..."
            />
          </div>

          <div className="form-group checkbox-group">
            <label>
              <input
                type="checkbox"
                checked={formData.available === 1}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    available: e.target.checked ? 1 : 0,
                  })
                }
              />
              <span>Disponível para venda</span>
            </label>
          </div>

          <button type="submit" disabled={loading} className="btn-submit">
            {loading ? (
              <>
                <div className="button-spinner"></div>
                Salvando...
              </>
            ) : cupcake ? (
              "Atualizar Cupcake"
            ) : (
              "Criar Cupcake"
            )}
          </button>
        </form>
      </div>
    </>
  );
};

export default AdminPanel;
