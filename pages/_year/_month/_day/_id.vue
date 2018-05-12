<template>
  <div>{{params.id}}</div>
</template>
<script>
export default {
  validate ({ params }) {
    return [params.year, params.month, params.day].every(
      id => /^\d+$/.test(id)
    )
  },
  fetch ({ redirect, params }) {
    return redirect('/' + params.id)
  }
}
</script>
