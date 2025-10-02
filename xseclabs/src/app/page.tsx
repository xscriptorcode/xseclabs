import { cookies } from "next/headers";
import { redirect } from "next/navigation";


export default async function Home() {
  const cookieStore = await cookies();
  const token = cookieStore.get("session-token");
  

  if (!token){
    redirect("/login");
  }

// example  const user = { email: "example", password: "example" };

  return (
    <div>
      <h1>Start</h1>
    </div>
  );
}