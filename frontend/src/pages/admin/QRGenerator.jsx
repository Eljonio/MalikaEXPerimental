import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'
import AdminHeader from '../../components/AdminHeader'

export default function QRGenerator() {
  const { restaurantId } = useParams()
  const [halls, setHalls] = useState([])
  const [tables, setTables] = useState([])
  const [selectedHall, setSelectedHall] = useState(null)
  const [loading, setLoading] = useState(true)
  const [generatingTable, setGeneratingTable] = useState(null)
  const [selectedTables, setSelectedTables] = useState([])
  const [showBulkActions, setShowBulkActions] = useState(false)

  useEffect(() => {
    fetchHalls()
  }, [restaurantId])

  const fetchHalls = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/halls`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setHalls(response.data)
      if (response.data.length > 0) {
        setSelectedHall(response.data[0].id)
        fetchTables(response.data[0].id)
      }
    } catch (err) {
      console.error('Error:', err)
    } finally {
      setLoading(false)
    }
  }

  const fetchTables = async (hallId) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/halls/${hallId}/tables`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setTables(response.data)
    } catch (err) {
      console.error('Error:', err)
    }
  }

  const generateLink = async (tableId) => {
    setGeneratingTable(tableId)
    try {
      const token = localStorage.getItem('token')
      const response = await axios.post(
        `/api/restaurants/${restaurantId}/halls/${selectedHall}/tables/${tableId}/generate-link`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      )

      // Обновить таблицы после генерации
      fetchTables(selectedHall)
      return response.data
    } catch (err) {
      console.error('Error generating link:', err)
      alert('Ошибка генерации ссылки')
    } finally {
      setGeneratingTable(null)
    }
  }

  const copyLink = (shortCode) => {
    const link = `http://217.11.74.100/t/${shortCode}`
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(link)
        .then(() => showNotification('Ссылка скопирована!'))
        .catch(() => fallbackCopy(link))
    } else {
      fallbackCopy(link)
    }
  }

  const fallbackCopy = (link) => {
    const textarea = document.createElement('textarea')
    textarea.value = link
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    showNotification('Ссылка скопирована!')
  }

  const showNotification = (message) => {
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 glass-card px-6 py-3 text-luxury-cream z-50 animate-fade-in'
    notification.textContent = message
    document.body.appendChild(notification)
    setTimeout(() => {
      notification.remove()
    }, 2000)
  }

  const downloadQR = async (shortCode, tableNumber) => {
    try {
      const link = `http://217.11.74.100/t/${shortCode}`
      // Используем публичный API для генерации QR
      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${encodeURIComponent(link)}`

      const response = await fetch(qrUrl)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `QR_Table_${tableNumber}_${shortCode}.png`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
      showNotification('QR-код скачан!')
    } catch (error) {
      console.error('Error downloading QR:', error)
      alert('Ошибка скачивания QR-кода')
    }
  }

  const printQR = (shortCode) => {
    const link = `http://217.11.74.100/t/${shortCode}`
    const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${encodeURIComponent(link)}`

    const printWindow = window.open('', '_blank')
    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>QR Code - ${shortCode}</title>
          <style>
            body {
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              min-height: 100vh;
              margin: 0;
              font-family: Arial, sans-serif;
            }
            img {
              max-width: 500px;
              height: auto;
            }
            .info {
              text-align: center;
              margin-top: 20px;
            }
            @media print {
              body {
                background: white;
              }
            }
          </style>
        </head>
        <body>
          <img src="${qrUrl}" alt="QR Code" />
          <div class="info">
            <h2>Стол - Сканируйте для меню</h2>
            <p>${link}</p>
          </div>
        </body>
      </html>
    `)
    printWindow.document.close()
    printWindow.onload = () => {
      printWindow.print()
    }
  }

  const toggleTableSelection = (tableId) => {
    setSelectedTables(prev =>
      prev.includes(tableId)
        ? prev.filter(id => id !== tableId)
        : [...prev, tableId]
    )
  }

  const generateBulkLinks = async () => {
    for (const tableId of selectedTables) {
      await generateLink(tableId)
    }
    setSelectedTables([])
    setShowBulkActions(false)
    showNotification(`Сгенерировано ${selectedTables.length} ссылок`)
  }

  const downloadAllQR = async () => {
    for (const table of tables.filter(t => t.short_code && selectedTables.includes(t.id))) {
      await downloadQR(table.short_code, table.table_number)
      await new Promise(resolve => setTimeout(resolve, 500)) // Задержка между скачиваниями
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center">
        <div className="glass-card p-8">
          <div className="flex items-center gap-3">
            <svg className="animate-spin h-8 w-8 text-luxury-gold" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-luxury-cream text-lg">Загрузка...</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern">
      <AdminHeader title="Генератор QR-кодов" />

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Выбор зала и массовые действия */}
        <div className="flex flex-wrap justify-between items-center gap-4 mb-8">
          <div className="flex-1 min-w-[250px]">
            <label className="block text-sm font-medium text-luxury-gold mb-3 tracking-wide">Выберите зал:</label>
            <select
              value={selectedHall || ''}
              onChange={(e) => {
                const hallId = Number(e.target.value)
                setSelectedHall(hallId)
                fetchTables(hallId)
                setSelectedTables([])
              }}
              className="input-glass"
            >
              {halls.map(hall => (
                <option key={hall.id} value={hall.id} className="bg-luxury-charcoal-light">{hall.name}</option>
              ))}
            </select>
          </div>

          <div className="flex gap-2">
            <button
              onClick={() => setShowBulkActions(!showBulkActions)}
              className={`btn-glass ${showBulkActions ? 'border-luxury-gold/40' : ''}`}
            >
              {showBulkActions ? '✓ Режим выбора' : 'Массовые действия'}
            </button>
            {showBulkActions && selectedTables.length > 0 && (
              <>
                <button
                  onClick={generateBulkLinks}
                  className="btn-luxury"
                >
                  Генерировать ({selectedTables.length})
                </button>
                <button
                  onClick={downloadAllQR}
                  className="btn-outline-gold"
                >
                  Скачать QR ({selectedTables.length})
                </button>
              </>
            )}
          </div>
        </div>

        {/* Инструкция */}
        <div className="glass-card p-6 mb-8 border-luxury-gold/30">
          <div className="flex items-start gap-4">
            <div className="text-3xl">💡</div>
            <div>
              <h3 className="text-lg font-bold text-luxury-gold mb-2">Как использовать</h3>
              <ul className="text-luxury-cream/80 text-sm space-y-1">
                <li>• Сгенерируйте уникальные ссылки для каждого стола</li>
                <li>• Скачайте QR-коды в формате PNG</li>
                <li>• Распечатайте QR-коды и разместите на столах</li>
                <li>• Гости смогут сканировать QR и открыть меню</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Сетка столов */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {tables.map(table => {
            const hasLink = table.short_code
            const isSelected = selectedTables.includes(table.id)

            return (
              <div
                key={table.id}
                className={`glass-card p-6 transition ${
                  showBulkActions ? 'cursor-pointer hover:border-luxury-gold/60' : ''
                } ${isSelected ? 'border-luxury-gold/60 bg-luxury-gold/5' : ''}`}
                onClick={() => showBulkActions && toggleTableSelection(table.id)}
              >
                {showBulkActions && (
                  <div className="flex justify-end mb-2">
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => {}}
                      className="w-5 h-5 rounded border-2 border-luxury-gold/40 bg-luxury-charcoal checked:bg-luxury-gold cursor-pointer"
                    />
                  </div>
                )}

                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-2xl font-bold text-luxury-cream">Стол #{table.table_number}</h3>
                    <p className="text-sm text-luxury-cream/60">Мест: {table.capacity}</p>
                    {table.is_vip && (
                      <span className="inline-block mt-2 px-3 py-1 bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold rounded text-xs">
                        ⭐ VIP
                      </span>
                    )}
                  </div>
                  {hasLink && (
                    <span className="px-3 py-1 bg-green-500/20 border border-green-500/40 text-green-400 rounded text-xs">
                      ✓ Активна
                    </span>
                  )}
                </div>

                {hasLink ? (
                  <div className="space-y-3">
                    {/* Превью QR */}
                    <div className="bg-white p-3 rounded-lg">
                      <img
                        src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(`http://217.11.74.100/t/${table.short_code}`)}`}
                        alt="QR Code"
                        className="w-full h-auto"
                      />
                    </div>

                    {/* Ссылка */}
                    <div className="p-3 glass-card text-xs break-all text-luxury-cream/80">
                      http://217.11.74.100/t/{table.short_code}
                    </div>

                    {/* Действия */}
                    <div className="space-y-2">
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          copyLink(table.short_code)
                        }}
                        className="w-full py-2 bg-blue-500/20 border border-blue-500/40 text-blue-400 rounded-lg hover:bg-blue-500/30 transition text-sm"
                      >
                        📋 Скопировать ссылку
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          downloadQR(table.short_code, table.table_number)
                        }}
                        className="w-full py-2 bg-green-500/20 border border-green-500/40 text-green-400 rounded-lg hover:bg-green-500/30 transition text-sm"
                      >
                        💾 Скачать QR
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          printQR(table.short_code)
                        }}
                        className="w-full py-2 bg-purple-500/20 border border-purple-500/40 text-purple-400 rounded-lg hover:bg-purple-500/30 transition text-sm"
                      >
                        🖨️ Печать
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          generateLink(table.id)
                        }}
                        disabled={generatingTable === table.id}
                        className="w-full py-2 glass-card hover:border-luxury-gold/40 text-luxury-cream/80 rounded-lg transition text-sm disabled:opacity-50"
                      >
                        {generatingTable === table.id ? '⏳ Генерация...' : '🔄 Перегенерировать'}
                      </button>
                    </div>

                    <p className="text-xs text-luxury-cream/50 text-center">
                      Код: <span className="font-mono">{table.short_code}</span>
                    </p>
                  </div>
                ) : (
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      generateLink(table.id)
                    }}
                    disabled={generatingTable === table.id}
                    className="w-full py-4 btn-luxury disabled:opacity-50"
                  >
                    {generatingTable === table.id ? '⏳ Генерация...' : '✨ Сгенерировать QR'}
                  </button>
                )}
              </div>
            )
          })}
        </div>

        {tables.length === 0 && (
          <div className="glass-card p-12 text-center">
            <p className="text-luxury-cream/50 mb-4">В этом зале нет столов</p>
            <p className="text-luxury-cream/40 text-sm">Создайте столы в разделе "Залы"</p>
          </div>
        )}
      </div>
    </div>
  )
}
