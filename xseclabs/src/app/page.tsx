import Image from "next/image";
import Login from "./components/login/login";
import Register from "./components/register/register";

export default function Home() {
  return (
    <div>
      <Login />
      <Register />
    </div>
  );
}
