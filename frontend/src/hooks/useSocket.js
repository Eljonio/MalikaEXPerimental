import { useEffect, useState } from 'react'
import io from 'socket.io-client'

export function useSocket(url = 'http://217.11.74.100:8000') {
  const [socket, setSocket] = useState(null)
  const [connected, setConnected] = useState(false)

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user') || '{}')
    const newSocket = io(url, {
      transports: ['websocket', 'polling']
    })

    newSocket.on('connect', () => {
      console.log('WebSocket connected')
      setConnected(true)
      
      if (user.role) {
        newSocket.emit('join_room', { role: user.role })
      }
    })

    newSocket.on('disconnect', () => {
      console.log('WebSocket disconnected')
      setConnected(false)
    })

    setSocket(newSocket)

    return () => {
      newSocket.close()
    }
  }, [url])

  return { socket, connected }
}
