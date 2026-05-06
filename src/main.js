import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

// Global styles — import 1 lần ở đây, không dùng @import trong scoped
import './assets/admin.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')