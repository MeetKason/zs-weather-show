<template>
  <n-modal
    class="go-view-private-deployment"
    title="系统公告"
    v-model:show="showModal"
    preset="card"
    size="small"
    transform-origin="center"
    style="width: 520px"
  >
    <n-space vertical>
      <n-text strong>中盛天气秀秀</n-text>
      <n-text depth="3">当前系统使用自部署前端、后端 API 和本地数据服务。</n-text>
    </n-space>
  </n-modal>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const showModal = ref(true)
</script>
