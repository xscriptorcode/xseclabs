import Login from "./components/login/login";
import Register from "./components/register/register";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";


export default function Home() {
  const cookieStore = cookies();
  const token = cookieStore.get("session-token");
  

  if (!token){
    redirect("/login");
  }

// example  const user = { email: "example", password: "example" };

  return (
    <div>
      <h1>Start {user.email}</h1>
    </div>
  );
}
