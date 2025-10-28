import React, { useState, useEffect } from "react";

const API_BASE = "http://localhost:3001/api";

// Helper para adicionar header de autenticação
const getAuthHeaders = () => {
  const user = JSON.parse(localStorage.getItem("user"));
  return {
    "Content-Type": "application/json",
    "x-user-id": user?.id || "",
  };
};

const AdminPanel = ({ user }) => {
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
      const res = await fetch(`${API_BASE}/admin/stats`, {
        headers: getAuthHeaders(),
      });

      if (!res.ok) {
        throw new Error("Erro ao carregar estatísticas");
      }

      const data = await res.json();
      setStats(data);
    } catch (error) {
      console.error("Erro ao carregar estatísticas:", error);
      showNotification("Erro ao carregar estatísticas", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchCupcakes = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/admin/cupcakes`, {
        headers: getAuthHeaders(),
      });

      if (!res.ok) {
        throw new Error("Erro ao carregar cupcakes");
      }

      const data = await res.json();
      setCupcakes(data);
    } catch (error) {
      console.error("Erro ao carregar cupcakes:", error);
      showNotification("Erro ao carregar cupcakes", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/orders`);

      if (!res.ok) {
        throw new Error("Erro ao carregar pedidos");
      }

      const data = await res.json();
      setOrders(data);
    } catch (error) {
      console.error("Erro ao carregar pedidos:", error);
      showNotification("Erro ao carregar pedidos", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCupcake = async (id) => {
    if (!window.confirm("Tem certeza que deseja deletar este cupcake?")) return;

    try {
      const res = await fetch(`${API_BASE}/admin/cupcakes/${id}`, {
        method: "DELETE",
        headers: getAuthHeaders(),
      });

      const result = await res.json();

      if (result.success) {
        showNotification("Cupcake deletado com sucesso!");
        fetchCupcakes();
      } else {
        showNotification(result.error || "Erro ao deletar cupcake", "error");
      }
    } catch (error) {
      showNotification("Erro ao deletar cupcake", "error");
    }
  };

  const handleUpdateOrderStatus = async (orderId, newStatus) => {
    try {
      const res = await fetch(`${API_BASE}/admin/orders/${orderId}`, {
        method: "PUT",
        headers: getAuthHeaders(),
        body: JSON.stringify({ status: newStatus }),
      });

      const result = await res.json();

      if (result.success) {
        showNotification("Status atualizado com sucesso!");
        fetchOrders();
      } else {
        showNotification(result.error || "Erro ao atualizar status", "error");
      }
    } catch (error) {
      showNotification("Erro ao atualizar status", "error");
    }
  };

  return (
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
          <OrdersTab orders={orders} onUpdateStatus={handleUpdateOrderStatus} />
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
        headers: getAuthHeaders(),
        body: JSON.stringify(formData),
      });

      const result = await res.json();
      if (result.success) {
        onSuccess();
      } else {
        alert(result.error || "Erro ao salvar cupcake");
      }
    } catch (error) {
      console.error("Erro ao salvar cupcake:", error);
      alert("Erro ao salvar cupcake");
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
