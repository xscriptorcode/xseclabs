export default function Footer () {
    return(
        <div className="flex justify-center text-center items-center p-2"
        style={{
            backgroundColor: 'var (--color-surface)',
            borderTop: '1px solid var (--color border)',
            color: 'var(--color-text-secondary)'
        }}>
            <p>X© Sec Labs</p>
        </div>
    )
}