<template>
  <div>
    <video style="width: 100%; height: 200px" controls playsinline muted>
      <source :src="fetchedVideoURL" type="video/mp4" />
    </video>
    <button @click="didTapDownloadVideoButton()">영상 로컬 저장</button>
    <button @click="didTapFetchVideoData()">영상 불러오기</button>
  </div>
</template>

<script>
const webkit = window.webkit.messageHandlers.WEBVIEW_BRIDGE;

let videoURL = "";

export default {
  data() {
    return {
      fetchedVideoURL: "",
    };
  },
  methods: {
    didTapDownloadVideoButton() {
      webkit.postMessage("didTapDownloadVideoButton");
    },
    saveLocalVideoURL(url) {
      videoURL = url;
      // alert(videoURL);
    },
    didTapFetchVideoData() {
      fetch(videoURL)
        .then((res) => {
          res
            .blob()
            .then((res2) => {
              const fetchedBlob = window.URL.createObjectURL(res2);
              this.fetchedVideoURL = fetchedBlob;
              // alert(url);
            })
            .catch((err) => {
              alert(`err ${err}`);
            });
        })
        .catch((err) => {
          alert(`err ${err}`);
        });
    },
  },
};
</script>

<style>
button {
  width: 50%;
  height: 100px;
  background-color: black;
  font-size: 22px;
  font-weight: bold;
  color: white;
  -webkit-tap-highlight-color: red;
}
</style>
