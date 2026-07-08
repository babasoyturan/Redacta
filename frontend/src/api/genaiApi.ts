import axios from 'axios';

const genaiApi = axios.create({
  baseURL: "/api/v1/genai",
});

export default genaiApi;
