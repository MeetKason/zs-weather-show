<template>
  <div class="go-aside-footer">
    <n-divider class="go-mt-0"></n-divider>
    <n-text depth="3">私有化部署</n-text>
  </div>
</template>

<script setup lang="ts">
defineProps({
  collapsed: Boolean
})
</script>

<style lang="scss" scoped>
@include go('aside-footer') {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 10px 20px;
  .n-divider {
    width: 100%;
  }
}
</style>
