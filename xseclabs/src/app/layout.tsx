import type { Metadata } from "next";
import "./globals.css";
import Footer from "./components/footer/footer";
import NavLinks, { Navbar } from "./components/navbar/navbar";


export const metadata: Metadata = {
  title: "X Sec Lab",
  description: "Site for CyberSecurity Reports",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`antialiased`}
      ><NavLinks />
        <main>
        {children}
        </main>
        <Footer />
      </body>
    </html>
  );
} 
