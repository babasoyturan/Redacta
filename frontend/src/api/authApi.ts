import axios from "axios";

const authApi = axios.create({
  baseURL: "/api/v1/authentication",
});

export default authApi;
