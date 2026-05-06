<template>
  <div id="app">
    <NavBar v-if="showNav" />
    <router-view />
    <Toast />
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from './stores/auth'
import NavBar from './components/NavBar.vue'
import Toast from './components/Toast.vue'

const route = useRoute()
const auth  = useAuthStore()

const showNav = computed(() =>
  !route.path.startsWith('/admin') && !route.path.startsWith('/staff')
)

onMounted(() => auth.fetchMe())
</script>