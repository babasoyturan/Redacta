import axios from 'axios';

const chatApi = axios.create({
  baseURL: "/api/v1/genai",
  headers: {
    'Content-Type': 'application/json',
  },
});

export default chatApi;
